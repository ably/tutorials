
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
            
            const translatedText = data['translations'][0]['translation'];
            if ( messageType === "send") {
                channel.publish('text', translatedText);
                channel.publish("user", {
                    "name": user.name,
                    "avatar": user.avatar
                });
            } else {
                show(translatedText, message.timestamp, otherUser);
            }
        })
        .catch(error => console.error(error)) 
    }


    const ably = new Ably.Realtime({
        key: YOUR_ABLY_API_KEY,
        clientId:`${user.id}`,
        echoMessages: false
    });

    //specify the channel the user should belong to. In this case, it is the `test` channel
    const channel = ably.channels.get('test');

    //Subscribe the user to the messages of the channel. So the use rwill receive each message sent to the test channel.

    channel.subscribe("text", function(message) {
        const selectedLanguage = $("#languageSelector").find(":selected").val();
        translateText(message, selectedLanguage)
    });

    //This gets the data of other users as they publish to the channel.
    channel.subscribe("user", (data) => {
        var dataObj = JSON.parse(JSON.stringify(data));
        if (dataObj.clientId != user.id) {
            let otherAvatar = dataObj.data.avatar;
            let otherName = dataObj.data.name;
            otherUser.name = otherName;
            otherUser.avatar = otherAvatar;
        }
    });


    //Get the send button, input field and language dropdown menu elements respectively.
    const sendButton =  document.getElementById("publish");
    const inputField = document.getElementById("input-field");
    const languageSelector = document.getElementById("languageSelector")

    //Add an event listener to check when the send button is clicked
    sendButton.addEventListener('click', function() {
        const input = inputField.value;
        const selectedLanguage = languageSelector.options[languageSelector.selectedIndex].value;
        inputField.value = "";
        let date = new Date(); 
        let timestamp = date.getTime()

        //display the message as it is using the show method
        show(input, timestamp, user, "send")
        
        //translate the text as a sent message
        translateText(input, selectedLanguage, "send")
    });    

        //This method displays the message.
    function show(text, timestamp, currentUser, messageType="receive") {
        const time = getTime(timestamp);
        const messageItem = `<li class="message ${messageType === "send" ? "sent-message": ""}">
            <picture>
                <img class="message-image" src=${currentUser.avatar} alt="" />
            </picture>
            <div class="message-info"> 
                <h5 class="message-name">${currentUser.name}</h5>
                <p class="message-text">${text}</p>
            </div> 
            <span class="message-time"> ${time}</span>
        </li>`
        // const messageItem = `<li class="message">${text}<span class="message-time"> ${time}</span></li`;
        $('#channel-status').append(messageItem)
    }

    //This method is used to convert a timestamp to 24hour time format, this is the format we will display the time of the message in.
    function getTime(unix_timestamp) {
        var date = new Date(unix_timestamp);
        var hours = date.getHours();
        var minutes = "0" + date.getMinutes();
        var seconds = "0" + date.getSeconds();
        // Will display time in 10:30:23 format
        var formattedTime = hours + ':' + minutes.substr(-2) + ':' + seconds.substr(-2);
        return formattedTime;
    }
}

index();
export default index;