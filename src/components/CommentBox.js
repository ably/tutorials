import React, { Component } from "react"
import Ably from "./Ably"
import axios from "axios"

class CommentBox extends Component {
  constructor(props) {
    super(props)
    this.addComment = this.addComment.bind(this)
  }
  async addComment(e) {
    // Prevent the default behaviour of form submit
    e.preventDefault()
    // Get the value of the comment box
    // and make sure it not some empty strings
    const comment = e.target.elements.comment.value.trim()
    const name = e.target.elements.name.value.trim()
    // Get the current time.
    const timestamp = Date.now()
    // Retrieve a random image from the Dog API
    const avatar = await (
      await axios.get("https://dog.ceo/api/breeds/image/random")
    ).data.message
    // Make sure name and comment boxes are filled
    if (name && comment) {
      const commentObject = { name, comment, timestamp, avatar }
      // Publish comment
      const channel = Ably.channels.get("comments")
      channel.publish("add_comment", commentObject, (err) => {
        if (err) {
          console.log("Unable to publish message err = " + err.message)
        }
      })
      // Clear input fields
      e.target.elements.name.value = ""
      e.target.elements.comment.value = ""
    }
  }
  render() {
    return (
      <div>
        <h1 className="title">Please leave your feedback below</h1>
        <form onSubmit={this.addComment}>
          <div className="field">
            <div className="control">
              <input
                type="text"
                className="input"
                name="name"
                placeholder="Your name"
              />
            </div>
          </div>
          <div className="field">
            <div className="control">
              <textarea
                className="textarea"
                name="comment"
                placeholder="Add a comment"
              ></textarea>
            </div>
          </div>
          <div className="field">
            <div className="control">
              <button className="button is-primary">Submit</button>
            </div>
          </div>
        </form>
      </div>
    )
  }
}
export default CommentBox
