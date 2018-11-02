var ably = new Ably.Rest('<YOUR-API-KEY>');
var url = '/channels';
var resultArea = document.getElementById('result');

//request a list of channels on button click
function enumerateChannels() {
  ably.request('get', url, { limit: 100, by: 'id' }, null, null, handleResultPage);
}

var channelCount = 0;
function handleResultPage(err, resultPage) {
  if(err || !resultPage.success) {
    resultArea.value += 'An error occurred; err = ' + (err || resultPage.errorMessage);
    return;
  }
  if(channelCount === 0) {
    if(resultPage.items.length == 0){
      resultArea.value += "Your app does not have any active channels\n";
      return;
    }
    resultArea.value += "Your app has the following active channels:\n";
  }

  resultPage.items.forEach(function(channel) {
    resultArea.value += (++channelCount) + ". " + channel + "\n";
  })

  if(resultPage.hasNext()) {
    resultPage.next(handleResultPage);
  };
}
