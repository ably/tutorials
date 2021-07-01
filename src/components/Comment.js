import React, { Component } from "react"
import axios from "axios"

class Comment extends Component {
  constructor(params) {
    super(params)
    this.messageDate = this.messageDateGet()
    this.state = {
      imgURL: "",
    }
  }
  messageDateGet() {
    const date = new Date(this.props.comment.timestamp)
    const dateTimeFormatOptions = {
      year: "2-digit",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    }
    const localeString = date.toLocaleString(undefined, dateTimeFormatOptions)
    return localeString
  }

  async getRandomImage() {
    try {
      const response = await axios.get(
        "https://dog.ceo/api/breeds/image/random"
      )
      console.log(response)
      this.setState({
        imgURL: response.data.message,
      })
    } catch (err) {
      console.log("error fetching image:", err)
    }
  }
  componentDidMount() {
    this.getRandomImage()
  }

  render() {
    const { imgURL } = this.state
    return (
      <article className="media">
        <figure className="media-left">
          <p className="image is-64x64">
            <img alt="dog pic" src={imgURL} />
          </p>
        </figure>
        <div className="media-content">
          <div className="content">
            <span className="user-name">{this.props.comment.name} </span>
            <span className="message-date">{this.messageDate}</span>
            <p>{this.props.comment.comment}</p>
          </div>
        </div>
      </article>
    )
  }
}
export default Comment
