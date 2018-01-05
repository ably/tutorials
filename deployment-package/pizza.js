const nlp = require('compromise');
const FuzzySet = require('fuzzyset');

module.exports = function processMessage(message, context) {
  if (message.length > 1000) {
    return formatResponse('Woah, calm down there... short and sweet, please.', context);
  }

  if (!context) {
    context = newContext();
  }

  const speech = parseMessage(message);
  const messageData = gatherDataFromMessage(speech, context);
  let responseMessage = constructResponseMessage(messageData, context);
  if(applyDataToContext(messageData, context)) {
    responseMessage += ' ' + elicitNext(context);
  }

  if (responseMessage) {
    return formatResponse(responseMessage, context);
  }

  if (context.elicitation === 'stonewalled') {
    context.elicitation = '';
    return formatResponse(`Ok, well let me know if you need anything.`, context);
  }

  responseMessage = tryOtherInterpretations(message, context);

  if (!responseMessage && context.confirmed && context.elicitation === 'confirm_order') {
    responseMessage = 'Great, your order has been placed. Next customer, please!';
  }

  return responseMessage
    ? formatResponse(responseMessage, context)
    : fail(context);
}

function applyDataToContext({ size, crust, sauce, toppings }, context) {
  let priceAdjustment = 0;
  let hasProblems = false, atLeastOneSuccessfulUpdate = false;

  if (size) {
    if (size.problem) {
      hasProblems = true;
    }
    else {
      priceAdjustment += size.priceAdjustment;
      context.size.value = size.product.sku;
      context.size.confirmed = true;
      atLeastOneSuccessfulUpdate = true;
    }
  }

  if (crust) {
    if (crust.problem) {
      hasProblems = true;
    }
    else {
      priceAdjustment += crust.priceAdjustment;
      context.crust.value = crust.product.sku;
      context.crust.confirmed = true;
      atLeastOneSuccessfulUpdate = true;
    }
  }

  if (sauce) {
    if (sauce.problem) {
      hasProblems = true;
    }
    else {
      priceAdjustment += sauce.priceAdjustment;
      context.sauce.value = sauce.product.sku;
      context.sauce.confirmed = true;
      atLeastOneSuccessfulUpdate = true;
    }
  }

  if (toppings) {
    if (toppings.problem) {
      hasProblems = true;
    }
    else {
      const selections = new Set(context.toppings.values);
      if (toppings.added) toppings.added.forEach(topping => selections.add(topping.sku));
      if (toppings.removed) toppings.removed.forEach(topping => selections.delete(topping.sku));
      context.toppings.values = Array.from(selections);
      context.toppings.confirmed = true;
      priceAdjustment += Math.max(0, selections.size - MAX_GRATIS_TOPPINGS) * 1.5;
      atLeastOneSuccessfulUpdate = true;
    }
  }

  context.price = 15 + priceAdjustment;

  return !hasProblems & atLeastOneSuccessfulUpdate;
}

function gatherDataFromMessage(speech, context) {
  const parts = speech.splitOn('(#TOPPING_TYPE|#CRUST_TYPE|#SAUCE_TYPE|#BASE_SIZE)');
  let currentTag, isNegation;
  let toppingsCount = context.toppings.values.length;
  const data = {};

  const isPositive = speech.has(POSITIVE_RESPONSE_PATTERNS);
  const isNegative = speech.has(NEGATIVE_RESPONSE_PATTERNS);

  for (let i = 0; i < parts.length; i++) {
    const [nextTag, sku, negationDetected] = getPizzaComponent(parts.get(i));

    if (!nextTag) {
      if (negationDetected) {
        isNegation = true;
      }
      continue;
    }

    // if this term is referring to a different component of the pizza, any prior negation no longer applies
    if (currentTag && nextTag !== currentTag) {
      isNegation = false;
    }

    currentTag = nextTag;
    const componentType = getDataKey(currentTag);
    const product = dictionary.lookupBySKU[sku];
    let details = data[componentType];

    switch (componentType) {
      case 'toppings': {
        if (!details) {
          data[componentType] = details = {
            isRevision: context[componentType].confirmed,
            priceAdjustment: 0,
            excessCount: 0,
          };
        }

        let subkey;
        const alreadyHasTopping = context.toppings.values.includes(product.sku);
        if (isNegation && !alreadyHasTopping) {
          subkey = 'alreadyOmitted';
        }
        else if (!isNegation && alreadyHasTopping) {
          subkey = 'alreadyPresent';
        }
        else {
          subkey = isNegation ? 'removed' : 'added';
          toppingsCount += subkey === 'added' ? 1 : -1;
          const oldExcessCount = details.excessCount;
          details.excessCount = Math.max(0, toppingsCount - MAX_GRATIS_TOPPINGS);
          if (oldExcessCount !== details.excessCount) {
            details.priceAdjustment = (details.excessCount - oldExcessCount) * product.charge;
          }
        }
        if (!details[subkey]) {
          details[subkey] = new Map();
        }
        details[subkey].set(sku, product);
        context.confirmed = false;
        break;
      }

      default: {
        if (isNegation || (details && details.product.sku === sku)) {
          break;
        }
        let multipleRefsToSameComponentType = false;
        const isRevision = context[componentType].confirmed;
        if (!details) {
          data[componentType] = details = {
            adjective: product.adjective,
            isRevision,
            priceAdjustment: 0,
            excessCount: 0,
          };
        }
        else if (isRevision) {
          multipleRefsToSameComponentType = true;
        }
        const isAlreadySpecifiedInOrder = context[componentType].value === sku;
        if (isAlreadySpecifiedInOrder) {
          if (multipleRefsToSameComponentType && details.product.sku !== sku) {
            break; // because the user has already indicated a revision, and this seems to be a reference to the prior value
          }
          details.problem = 'already_specified';
          details.product = product;
        }
        else if (details.problem === 'already_specified') {
          delete details.problem; // because the prior reference to the existing value was probably a request to replace the old value with the new
          details.product = product;
        }
        else if (multipleRefsToSameComponentType && details.product) {
          if (!Array.isArray(details.product)) {
            details.priceAdjustment = 0;
            details.problem = 'too_many';
            details.product = [details.product, product];
          }
          else {
            details.product.push(product);
          }
        }
        else {
          details.product = product;
          details.priceAdjustment = product.charge - context[componentType].charge;
        }
        context.confirmed = false;
      }
    }
  }

  if (context.elicitation) {
    switch(context.elicitation) {
      case 'new_order':
        if (isNegative) {
          context.elicitation = 'stonewalled';
        }
        break;

      case 'confirm_upgrade_size':
        context.size.confirmed = true;
        if (isPositive && !data.size) {
          context.elicitation = '';
          const product = dictionary.lookupBySKU['large_size'];
          data.size = {
            product,
            isRevision: true,
            adjective: product.adjective,
            priceAdjustment: product.charge - context.size.charge,
          };
        }
        break;

      case 'confirm_crust':
        if (isPositive && !data.crust) {
          context.elicitation = '';
          context.crust.confirmed = true;
          const product = dictionary.lookupBySKU['regular_crust'];
          data.crust = {
            product,
            isRevision: true,
            adjective: product.adjective,
            priceAdjustment: product.charge - context.crust.charge,
          };
        }
        break;

      case 'confirm_sauce':
        if (isPositive && !data.sauce) {
          context.elicitation = '';
          context.sauce.confirmed = true;
          const product = dictionary.lookupBySKU['pizza_sauce'];
          data.sauce = {
            product,
            isRevision: true,
            adjective: product.adjective,
            priceAdjustment: product.charge - context.sauce.charge,
          };
        }
        break;

      case 'confirm_toppings':
        if (isNegative && !data.toppings) {
          context.elicitation = '';
          context.toppings.confirmed = true;
        }
        break;

      case 'confirm_order':
        if (!data.size && !data.crust && !data.sauce && !data.toppings) {
          if (isPositive) {
            context.confirmed = true;
          }
          else if (isNegative) {
            context.elicitation = 'stonewalled';
          }
        }
        break;
    }
  }

  return data;
}

function getDataKey (tag) {
  switch (tag) {
    case 'BASE_SIZE': return 'size';
    case 'CRUST_TYPE': return 'crust';
    case 'SAUCE_TYPE': return 'sauce';
    case 'TOPPING_TYPE': return 'toppings';
  }
}

function getPizzaComponent(part) {
  const term = part.terms().data()[0];
  const tags = term.tags.filter(tag => CUSTOM_TAGS.has(tag));
  const bestTag = tags[0] || null;
  let word = term.normal;
  let isExclusion = false;
  if (bestTag === null) {
    isExclusion = part.has('(remove|without|exclude|cancel|omit|eliminate|ditch|drop|forget|not|no|kill|hold)')
      || part.has('take (out|away|off|back)');
    const verbs = nlp(part.out('text')).verbs().data();
    if (verbs.some(term => term.interpret.negative)) {
      isExclusion = !isExclusion;
    }
  }
  return [bestTag, word, isExclusion];
}

function tryOtherInterpretations (message, context) {
  const matches = DATA_REQUEST_INITIATORS.get(message);
  if(matches && matches[0][0] >= 0.5) {
    return `Your current order is ${formatOrderDetails(context)}.`;
  }
}

function formatOrderDetails (context) {
  const size = dictionary.lookupBySKU[context.size.value].adjective;
  const crust = dictionary.lookupBySKU[context.crust.value].adjective;
  const sauce = dictionary.lookupBySKU[context.sauce.value].adjective;
  const toppings = new Map(context.toppings.values.map(sku =>
    [sku, dictionary.lookupBySKU[sku]]));

  return `a ${size}-sized, ${crust} pizza with ${sauce} sauce and ${concatenateItemList(toppings)}, ` +
    `the total of which comes to ${formatPrice(context.price)}`
}

function constructResponseMessage({ size, crust, sauce, toppings }, context) {
  let message = '', noop = false;

  const requestedValidSize = size && !size.problem;
  const requestedValidCrust = crust && !crust.problem;
  const requestedValidSauce = sauce && !sauce.problem;

  if (size) {
    if (size.problem) {
      if (size.problem === 'already_specified') {
        message = `you've already specified ${size.adjective} size`;
      }
      else if (size.problem === 'too_many') {
        message = `I'm not quite sure which size you want`;
      }
    }
    else {
      message = size.isRevision
        ? `I've changed your order to a ${size.adjective}`
        : message = `we're going to make you a ${size.adjective}`;

      if (!crust || crust.problem) {
        message += ' pizza';
      }

      if(context.size.confirmed) {
        message += formatPriceAdjustmentSuffix(size.priceAdjustment);
      }
    }
  }

  if (crust) {
    if (crust.problem) {
      if (size) {
        message += '. ';
      }
      if (crust.problem === 'already_specified') {
        message = `I've already locked in the ${crust.adjective} crust for your pizza`;
      }
      else if (crust.problem === 'too_many') {
        message = `I'm unclear which crust you want`;
      }
    }
    else {
      message += requestedValidSize
        ? `, ${crust.adjective} pizza`
        : crust.isRevision
          ? `I've changed your pizza to a ${crust.adjective} crust`
          : `your pizza will be made with a ${crust.adjective} crust`;

      message += formatPriceAdjustmentSuffix(crust.priceAdjustment);
    }
  }

  if (sauce) {
    if (sauce.problem) {
      if (size || crust) {
        message += '. ';
      }
      if (sauce.problem === 'already_specified') {
        message = `Your pizza already has ${sauce.adjective} sauce`;
      }
      else if (sauce.problem === 'too_many') {
        message = `I'm unclear which sauce you want`;
      }
    }
    else if (sauce.isRevision) {
      let append = true;
      if (requestedValidSize || requestedValidCrust) {
        if ((requestedValidSize && size.isRevision) || (requestedValidCrust && crust.isRevision)) {
          message += ` with ${sauce.adjective} sauce`;
          append = false;
        }
        else {
          message += `, and `;
        }
        if (append) {
          message += `I've changed the sauce to ${sauce.adjective}`
        }
      }
    }
    else {
      const prefix = requestedValidSize || (requestedValidCrust && crust.isRevision)
        ? ' with' : requestedValidCrust ? ' and' : `${message.length > 0 ? '. ' : ''}Your pizza will have`;
      message += `${prefix} ${sauce.adjective} sauce`;
    }
  }

  if (toppings) {
    const { added, removed, alreadyOmitted, alreadyPresent } = toppings;

    const complexity = (size ? 1 : 0) + (crust ? 1 : 0) + (sauce ? 1 : 0);
    if (added || removed) {
      if (complexity > 0) {
        message += context.toppings.confirmed ? `. I've` : `. We'll`;
        if (complexity > 2) {
          message += ` also`;
        }
      }

      if (toppings.isRevision || complexity > 0) {
        if (complexity === 0) {
          message += context.toppings.confirmed ? `I've` : `We'll`;
        }
        if (added) {
          message += ` ${context.toppings.confirmed ? 'added' : 'top it with'} ${concatenateItemList(added)}`;
        }
        if (removed) {
          if (added) {
            message += ` and`;
          }
          message += ` removed the ${concatenateItemList(removed)}`;
        }
      }
      else if (added) {
        message += `your pizza will be topped with ${concatenateItemList(added)}`;
      }
      else {
        message += `your pizza will not have any ${concatenateItemList(removed)}`;
      }
    }

    if (toppings.priceAdjustment) {
      const explanation = toppings.excessCount === 0 ? ''
        : toppings.excessCount > 1
          ? ` for ${toppings.excessCount} toppings beyond the maximum of ${MAX_GRATIS_TOPPINGS}`
          : ` for the extra topping above the maximum of ${MAX_GRATIS_TOPPINGS}`;
      message += formatPriceAdjustmentSuffix(toppings.priceAdjustment, explanation);
    }

    if (alreadyOmitted || alreadyPresent) {
      if(message.length > 0) {
        message += '.';
      }
      else {
        noop = true;
      }
      const firstWord = message.length > 0 ? ' Your' : 'your';
      if (alreadyPresent) {
        message += `${firstWord} pizza already has ${concatenateItemList(alreadyPresent)}`;
      }
      if (alreadyOmitted) {
        const items = concatenateItemList(alreadyOmitted, 'or');
        if (alreadyPresent) {
          message += ` and does not have ${items}`;
        }
        else {
          message += `${firstWord} pizza doesn't have any ${items}`;
        }
      }
    }
  }

  if (message.length > 0) {
    message = `${randomMessage(noop ? NOOP_STATEMENT_INITIATORS : GENERAL_STATEMENT_INITIATORS)} ${message}.`;
  }

  return message;
}

function formatPriceAdjustmentSuffix(amount, explanation) {
  if (amount === 0) return '';
  const prefix = amount > 0 ? '+' : '-';
  return ` (${prefix}${formatPrice(amount)}${explanation || ''})`;
}

function formatPrice (price) {
  if (price === 0) return 'free';
  price = Math.abs(price);
  if (price < 1) return String(Math.floor(price * 100)) + 'c';
  let s = `$${price}`;
  let i = s.indexOf('.');
  if (i === -1) return s + '.00';
  const zeros = s.length - i - 1;
  if (zeros > 2) return s.substr(0, s.length - zeros + 2);
  if (zeros < 2) s += '0';
  return s;
}

function concatenateItemList(items, conjunction = 'and') {
  const names = Array.from(items.values()).map(item => item.name.toLowerCase());
  switch (names.length) {
    case 1: return names[0];
    case 2: return `${names[0]} ${conjunction} ${names[1]}`
  }
  let str = names[0];
  for (let i = 1; i < names.length; i++) {
    str += (i === names.length - 1 ? ` ${conjunction} ` : ', ') + names[i];
  }
  return str;
}

function elicitNext(context) {
  const initiator = randomMessage(GENERAL_ELICITATION_INITIATORS);
  context.remainingTries = 5;
  if(!context.size.confirmed) {
    context.elicitation = 'confirm_upgrade_size';
    return `${initiator} would you like to upgrade to a large pizza for $1.50 extra? Available options are large, regular or small.`;
  }
  if(!context.crust.confirmed) {
    context.elicitation = 'confirm_crust';
    return `${initiator} is a regular deep pan crust ok? Available options are pan (regular), deep pan, thin and crispy, cheese crust, and gluten-free.`;
  }
  if(!context.sauce.confirmed) {
    context.elicitation = 'confirm_sauce';
    return `${initiator} are you happy with pizza sauce? We also have BBQ sauce or garlic creme fraiche, which is a popular choice with chicken and seafood pizza toppings.`;
  }
  if(!context.toppings.confirmed) {
    context.elicitation = 'confirm_toppings';
    return `${initiator} do you want any other toppings do you want on your pizza? All it is so far is mozarella cheese.`;
  }
  context.elicitation = 'confirm_order';
  return `That comes to ${formatPrice(context.price)}. Shall I lock in your order?`
}

function newContext() {
  return {
    elicitation: 'new_order',
    remainingTries: 5,
    toppings: { values: ['mozzarella_topping'], confirmed: false, charge: 0 },
    crust: { value: 'regular_crust', confirmed: false, charge: 0 },
    sauce: { value: 'pizza_sauce', confirmed: false, charge: 0 },
    size: { value: 'medium_size', confirmed: false, charge: 15 },
    confirmed: false,
    price: 15
  };
}

function formatResponse(message, context) {
  return { message, context };
}

function fail(context) {
  if(context.remainingTries > 0) {
    context.remainingTries--;
    if (context.remainingTries === 0) {
      context.elicitation = '';
    }
    const message = RETRY_RESPONSES[context.remainingTries];
    return formatResponse(message, context);
  }
  else {
    const message = randomMessage(GENERAL_FAILURE_RESPONSES);
    return formatResponse(message, context);
  }
}

function randomMessage(messages) {
  const index = Math.floor(Math.random() * messages.length);
  return messages[index];
}

function parseMessage(message) {
  message = normalizeMessage('#Adjective #Noun', message);
  message = normalizeMessage('#Noun #Noun', message);
  message = normalizeMessage('#Noun', message);
  message = normalizeMessage('#Adjective', message);
  return nlp(message, dictionary.lexicon);
}

function normalizeMessage(pattern, message) {
  const speech = nlp(message, dictionary.lexicon);
  speech.match(pattern).forEach(m => {
    const alreadyMatched = m.terms().data().some(t => t.tags.some(tag => CUSTOM_TAGS.has(tag)));
    if (alreadyMatched) {
      return;
    }
    const possibilities = dictionary.pizzaWords.get(m.out('normal'));
    if (!possibilities || possibilities.length === 0) {
      return;
    }
    const [score, candidate] = possibilities[0];
    if(score < 0.7) {
      return;
    }
    const tokenValue = dictionary.lookupByName[dictionary.canon[candidate]].sku;
    message = message.replace(m.trim().out('text'), tokenValue);
  });
  return message;
}

function buildDictionary() {
  var pizzaWords = new FuzzySet();
  const lookupByName = {}, lookupBySKU = {}, canon = {}, lexicon = {};

  addTerms('BASE_SIZE', BASE_SIZE, pizzaWords, canon, lookupByName, lookupBySKU, lexicon);
  addTerms('CRUST_TYPE', CRUST_TYPE, pizzaWords, canon, lookupByName, lookupBySKU, lexicon);
  addTerms('SAUCE_TYPE', SAUCE_TYPE, pizzaWords, canon, lookupByName, lookupBySKU, lexicon);
  addTerms('TOPPING_TYPE', TOPPING_TYPE, pizzaWords, canon, lookupByName, lookupBySKU, lexicon);

  return { lexicon, pizzaWords, canon, lookupByName, lookupBySKU };
}

function addTerms(type, options, pizzaWords, canon, lookupByName, lookupBySKU, lexicon) {
  for (let sku in options) {
    const { synonyms, charge, adjective, nouns } = options[sku];
    const entry = {
      name: synonyms[0],
      adjective,
      type,
      sku,
      charge
    };
    lookupByName[synonyms[0]] = entry;
    lookupBySKU[sku] = entry;
    synonyms.forEach(term => {
      lexicon[sku] = type;
      pizzaWords.add(term);
      canon[term] = synonyms[0];
    });
    if (nouns) { // (special cases where nlp compromise fails)
      nouns.forEach(noun => lexicon[noun] = 'Noun');
    }
  }
  return lexicon;
}

const GENERAL_FAILURE_RESPONSES = [
  `Sorry, I don't understand.`,
  `That doesn't make sense. I'm just a chat bot though, so it's probably my fault.`,
  `Could you say that in a different way?`,
  `Ummm... yeah, I'm not getting your meaning. Perhaps try rephrasing?`,
  `I apologise, my language skills are a little lacking. Try simplifying, or elaborating.`,
  `I'm sorry, I'm not quite sure what you mean by that.`,
  `I don't quite know what you're trying to say. Are there any similar words, phrasings or spellings you could use?`,
];

const RETRY_RESPONSES = [
  `I apologise, but I give up, and I can't remember what I asked you, anyway.`,
  `I'm sorry, I'm honestly not sure what you mean... try again, maybe?`,
  `Hmm, I'm really having trouble understanding what you're trying to convey. Is there no other way you could say it?`,
  `Still not sure what you mean. Perhaps try using synonyms, or different spellings.`,
  `Sorry, I didn't quite get that. Could you rephrase?`,
];

const POSITIVE_RESPONSE_PATTERNS = `(yes|ok|sure|yep|yeah|roger|aye|yup|affirmative)`;
const NEGATIVE_RESPONSE_PATTERNS = `(no|nope|negative|nah|nuh|nay|naw|nup)`;

const DATA_REQUEST_INITIATORS = [
  `show my order`,
  `show me my order`,
  `can I get an update on my order`,
  `whats in my order`,
  `how much is the price`,
  `how much is my pizza`,
  `can I see my order`,
  `can I see what I have ordered`,
  `can I see whats on my pizza`,
  `what is in my order`,
  `get the price`,
  `what have I ordered`,
  `what is my order`,
  `what did I order`,
  `what is on my order`,
  `how much is the order`,
  `how much will it cost`,
  `show the price`,
  `what will this cost`,
  `whats the price`,
  `whats the cost`,
  `whats the charge`,
  `whats that come to`,
  `whats the price come to`,
  `whats the order cost so far`,
].reduce((dict, text) => (dict.add(text), dict), new FuzzySet());

const GENERAL_ELICITATION_INITIATORS = [
  `Also,`,
  `Next`,
  `Ok, so`,
  `So`,
  `And`,
];

const NOOP_STATEMENT_INITIATORS = [
  `Of course, though`,
  'Actually,',
  'No need,',
  'I would, but',
  'Not necessary,'
];

const GENERAL_STATEMENT_INITIATORS = [
  `Ok,`,
  `Right,`,
  `Alright,`,
  `Uh huh,`,
  `Ok then,`,
  `Great, so`,
  `Ok, so`,
  `Yep ok, so`,
  `No problem,`,
  `Sure,`,
];

const CUSTOM_TAGS = new Set([
  'TOPPING_TYPE',
  'CRUST_TYPE',
  'SAUCE_TYPE',
  'BASE_SIZE'
]);

const SAUCE_TYPE = {
  pizza_sauce: { charge: 1.5, adjective: 'pizza', synonyms: ['Pizza Sauce', 'Tomato Sauce', 'Tomato', 'Pizza Sauce', 'Tomato Paste'] },
  bbq_sauce: { charge: 1.5, adjective: 'barbeque', synonyms: ['Barbeque Sauce', 'BBQ Sauce', 'Barbeque'], nouns: ['bbq sauce', 'bbq'] },
  garlic_sauce: { charge: 1.5, adjective: 'garlic', synonyms: ['Garlic Creme Fraiche', 'Creme Fraiche', 'Cream Fresh', 'Garlic Sauce', 'Garlic Cream'] },
};

const BASE_SIZE = {
  large_size: { charge: 18, adjective: 'large', synonyms: ['Large', 'Big', 'Largest', 'Biggest', 'Maximum', 'Max'] },
  medium_size: { charge: 15, adjective: 'medium', synonyms: ['Medium', 'Regular', 'Normal', 'Standard'] },
  small_size: { charge: 12, adjective: 'small', synonyms: ['Small', 'Smallest', 'Little', 'Personal'] },
};

const MAX_GRATIS_TOPPINGS = 4;

const TOPPING_TYPE = {
  anchovies_topping: { charge: 1.5, synonyms: ['Anchovies'] },
  avocado_topping: { charge: 1.5, synonyms: ['Avocado'] },
  bacon_topping: { charge: 1.5, synonyms: ['Bacon'] },
  basil_topping: { charge: 1.5, synonyms: ['Basil'] },
  beef_topping: { charge: 1.5, synonyms: ['Beef', 'Ground Beef'] },
  chicken_topping: { charge: 1.5, synonyms: ['Chicken'] },
  chives_onions_topping: { charge: 1.5, synonyms: ['Chives'] },
  chorizo_topping: { charge: 1.5, synonyms: ['Chorizo'] },
  fetta_topping: { charge: 1.5, synonyms: ['Fetta', 'Fetta Cheese'] },
  green_peppers_topping: { charge: 1.5, synonyms: ['Peppers', 'Green Peppers', 'Green Capsicum'] },
  ham_topping: { charge: 1.5, synonyms: ['Ham'] },
  jalapenos_topping: { charge: 1.5, synonyms: ['Jalapenos', 'Jalapeno Peppers'] },
  mozzarella_topping: { charge: 1.5, synonyms: ['Mozzarella Cheese', 'Cheese'] },
  mushrooms_topping: { charge: 1.5, synonyms: ['Mushrooms'] },
  olives_topping: { charge: 1.5, synonyms: ['Spanish Olives', 'Olives'] },
  onions_topping: { charge: 1.5, synonyms: ['Red Onions', 'Onions'] },
  oregano_topping: { charge: 1.5, synonyms: ['Oregano'] },
  pepperoni_topping: { charge: 1.5, synonyms: ['Pepperoni'] },
  pineapple_topping: { charge: 1.5, synonyms: ['Pineapple'] },
  red_peppers_topping: { charge: 1.5, synonyms: ['Peppers', 'Red Peppers', 'Capsicum', 'Red Capsicum'] },
  shrimp_topping: { charge: 1.5, synonyms: ['Shrimp', 'Prawns', 'Seafood'] },
  spinach_topping: { charge: 1.5, synonyms: ['Spinach'] },
  spring_onions_topping: { charge: 1.5, synonyms: ['Spring Onions', 'Shallots'] },
};

const CRUST_TYPE = {
  deep_crust: { charge: 0, adjective: 'deep-pan', synonyms: ['Deep Pan', 'Deep Crust', 'Deep Dish', 'Thick Crust'] },
  regular_crust: { charge: 0, adjective: 'regular', synonyms: ['Regular', 'Regular Crust', 'Normal', 'Standard'] },
  thin_and_crispy_crust: { charge: 0, adjective: 'thin & crispy', synonyms: ['Thin & Crispy', 'Thin Crust', 'Crispy Crust'] },
  cheese_crust: { charge: 2.5, adjective: 'cheesy', synonyms: ['Cheesy Crust', 'Cheesey Crust', 'Cheese Crust'] },
  glutenfree_crust: { charge: 1.5, adjective: 'gluten-free', synonyms: ['Gluten Free', 'No Gluten', 'Gluten-Free Crust'] },
};

const dictionary = buildDictionary();
