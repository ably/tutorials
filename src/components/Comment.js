import React, { Component } from 'react';
import filterBadWords from './ProfanityFilter';

class Comment extends Component {
  constructor(params) {
    super(params);
    this.userName = filterBadWords(this.props.comment.name);
    this.messageDate = this.messageDateGet();
    this.commentText = filterBadWords(this.props.comment.comment);
  }

  messageDateGet() {
    const date = new Date(this.props.comment.timestamp);
    const dateTimeFormatOptions = {
      "year": '2-digit',
      "month": '2-digit',
      "day": '2-digit',
      "hour": '2-digit',
      "minute": '2-digit'
    };
    const localeString = date.toLocaleString(undefined, dateTimeFormatOptions);

    return localeString;
  }

  render() {
    return (
      <article className="media">
        <figure className="media-left">
          <p className="image is-64x64">
            <img src="https://bulma.io/images/placeholders/128x128.png" alt="Avatar" />
          </p>
        </figure>
        <div className="media-content">
          <div className="content">
            <span className="user-name">{this.userName}</span>
            <span className="message-date">{this.messageDate}</span>
            <p>{this.commentText}</p>
          </div>
        </div>
      </article>
    );
  }
}

export default Comment;
