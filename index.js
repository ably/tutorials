
import '@babel/polyfill' 
function index() {
    //This method retrieves a list of all languages
    async function getLanguages() {
        let response = await fetch("/api/get-languages", {
            method: 'GET'
        }); 
        return await response.json();
    }

   //This method retrieves a list of all language models
    async function getModels() {
        let response = await fetch("/api/get-model-list", {
            method: 'GET'
        })
        return await response.json();
    }

    getTranslatableLangauges()

    function getTranslatableLangauges() {
        //get languages and all language models
        const allLanguages = getLanguages();
        const models = getModels();
        
        //resolve the promises
        Promise.all([allLanguages, models]).then( values => {
            const allLanguages =  values[0].languages;
            const models = values[1].models;
            
            //get translation models that have English as their source
            const englishModels = models.filter(model => model.source === "en");
            
            //get all languages that can be translated from English
            let translatableEnglishLanguages = englishModels.map(model => {
                return allLanguages.find(language => model.target === language.language)
            })
        
            //sort languages
            translatableEnglishLanguages.sort((a,b) => {
                var nameA = a.name.toUpperCase(); // ignore upper and lowercase
                var nameB = b.name.toUpperCase(); // ignore upper and lowercase
                if (nameA < nameB) {
                return -1;
                }
                if (nameA > nameB) {
                return 1;
                }
            
                // names must be equal
                return 0;
            })
            const languagesMap = translatableEnglishLanguages.map( language => 
                `<option value="${language.language}">${language.name}</option>`
            )
            $("#languageSelector").html(languagesMap)
        })
    }


  //this method translates the text using the `translate` enpoint created. 
    function translateText(message, language, messageType = "receive") {
        //check if the message is a sent message or received message
        const text = messageType === "send" ? message: message.data;
        const translateParams = {
            text: text,
            modelId: messageType === "send" ? `${language}-en` : `en-${language}`,
        };
        var nmtValue  = '2019-09-28';
        fetch('/api/translate', {
            method: 'POST',
            body: JSON.stringify(translateParams),
            headers: new Headers({
                'X-WDC-PL-OPT-OUT': $('input:radio[name=serRadio]:radio:checked').val(),
                'X-Watson-Technology-Preview': nmtValue,
                "Content-Type": "application/json"
            }),
        })
        .then(response => response.json())
        .then(data => {
            console.log(data)
        })
        .catch(error => console.error(error)) 
    }
}

index();
export default index;