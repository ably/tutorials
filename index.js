
import '@babel/polyfill' 
function index() {

    // A method to randomly get an item from an array
    function getRandomArbitrary(min, max) {
        return Math.floor(Math.random() * (max - min) + min);
    }

    //a list of avatars that will randomly be assigned to each app user
    const avatarsInAssets = [
        'https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_8.png?1536042504672',
        'https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_3.png?1536042507202',
        'https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_6.png?1536042508902',
        'https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_10.png?1536042509036',
        'https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_7.png?1536042509659',
        'https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_9.png?1536042513205',
        'https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_2.png?1536042514285',
        'https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_1.png?1536042516362',
        'https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_4.png?1536042516573',
        'https://cdn.glitch.com/0bff6817-d500-425d-953c-6424d752d171%2Favatar_5.png?1536042517889'
    ]

    //a list of names that will randomly be assigned to each app user
    const namesInAssets = [
        'Sarah Tancredi',
        'Michael Scoffied',
        'Waheed Musa',
        'Ada Lovelace',
        'Charles Gabriel',
        'Mr White',
        'Lovely Spring',
        'William Shakespare',
        'Prince Williams',
        'Queen Rose'
    ]

    //create a user object by randomly assigning an id, an avatar and a name. 
    let user = {
        id: "id-" + Math.random().toString(36).substr(2, 16),
        avatar: avatarsInAssets[getRandomArbitrary(0, 9)],
        name: namesInAssets[getRandomArbitrary(0, 9)]
    };
    //this object will hold the data of other users that send messages to the channel
    let otherUser = {};

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