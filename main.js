var ably = new Ably.Rest('<YOUR-API-KEY>');
var URL = '/channels';
var resultArea = document.getElementById('result');
var channelCount = 0;
function enumerateChannels() {
    ably.request('get', URL, { limit: 100, direction: 'forwards' }, null, null, (err, results) => {
        if (err) {
            console.log('An error occurred; err = ' + err.toString());
        } else {
            console.log('Success! status code was ' + results.statusCode);
            console.log(results.items.length + ' items returned');
            resultArea.value += "Your API key has the following active channels:\n";
            results.first((err, resultPage) => {
                console.log(resultPage.items);
                for (var i = 0; i < resultPage.items.length; i++) {
                    var resultObj = JSON.parse(JSON.stringify(resultPage.items[i]));
                    channelCount++;
                    resultArea.value += channelCount + ". " + resultObj.name + "\n";

                }
            })
            if (results.hasNext()) {
                results.next(function (err, nextPage) {
                    console.log(nextPage.items.length + ' more items returned');
                });
            }
        }
    })
}