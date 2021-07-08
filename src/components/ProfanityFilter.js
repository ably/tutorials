import badWords from "bad-words"
const filter = new badWords()
function clean(textToFilter) {
  return filter.clean(textToFilter || "")
}
export default clean
