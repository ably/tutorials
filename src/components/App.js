import React, { Component } from "react"
import CommentBox from "./CommentBox"
import Comments from "./Comments"
import Ably from "./Ably"

class App extends Component {
  constructor(props) {
    super(props)
    this.handleAddComment = this.handleAddComment.bind(this)
    this.state = {
      comments: [],
    }
  }

  componentDidMount() {
    const channel = Ably.channels.get("comments")
    channel.attach()
    channel.once("attached", () => {
      channel.history((err, page) => {
        // create a new array with comments only in an reversed order (i.e old to new)
        const comments = Array.from(page.items, (item) => item.data)
        this.setState({ comments })
        channel.subscribe((msg) => {
          this.handleAddComment(msg.data)
        })
      })
    })
  }

  handleAddComment(comment) {
    this.setState((prevState) => {
      return {
        comments: [comment].concat(prevState.comments),
      }
    })
  }

  render() {
    return (
      <section className="section">
        <div className="container">
          <div className="columns">
            <div className="column is-half is-offset-one-quarter">
              <CommentBox />
              <Comments comments={this.state.comments} />
            </div>
          </div>
        </div>
      </section>
    )
  }
}
export default App
