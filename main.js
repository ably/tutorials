var URL = '/channels';
        var resultArea = document.getElementById('result');
        var channelCount = 0;
        //request a list of channels on button click
        function enumerateChannels() {
            var userApiKey = document.getElementById('user-api-key').value;
            var ably = new Ably.Rest(userApiKey)
            ably.request('get', URL, { limit: 100, direction: 'forwards' }, null, null, (err, results) => {
                if (err) {
                    resultArea.value += 'An error occurred; err = ' + err.toString();
                    return;
                } else {
                    if(results.items.length == 0){
                        resultArea.value += "Your API key does not have any active channels\n";
                        return;
                    }
                    resultArea.value += "Your API key has the following active channels:\n";
                    for (var i = 0; i < results.items.length; i++) {
                        var resultObj = JSON.parse(JSON.stringify(results.items[i]));
                        channelCount++;
                        resultArea.value += channelCount + ". " + resultObj.name + "\n";
                    }
                    displayNextPage(results)
                    
                }
                
            })
        }
    
        function displayNextPage(results){
            if(results.isLast()){
                return;
            } 
            results.next((err, nextPage) => {
                for (var i = 0; i < results.items.length; i++) {
                    var resultObj = JSON.parse(JSON.stringify(results.items[i]));
                    channelCount++;
                    resultArea.value += channelCount + ". " + resultObj.name + "\n";
                }
                displayNextPage(nextPage)
            })
            
        }