import React, { Component } from 'react';
import Ably from '../ably';

class CommentBox extends Component {
  addComment(e) {
    // Prevent the default behaviour of form submit
    e.preventDefault();

    // Get the value of the comment box
    // and make sure it not some empty strings
    const comment = e.target.elements.comment.value.trim();
    const name = e.target.elements.name.value.trim();

    // Make sure name and comment boxes are filled
    if (name && comment) {
      const commentObject = { name, comment };

      // Publish comment
      const channel = Ably.channels.get('comments');
      channel.publish('add_comment', commentObject);

      // Clear input fields
      e.target.elements.comment.value = '';
      e.target.elements.name.value = '';
    }
  }

  render() {
    return (
      <div>
        <h1 className="title">Kindly leave your thoughts below</h1>
        <form onSubmit={this.addComment}>
          <div className="field">
            <div className="control">
              <input type="text" className="input" name="name" placeholder="Your name"/>
            </div>
          </div>
          <div className="field">
            <div className="control">
              <textarea className="textarea" name="comment" placeholder="Add a comment"></textarea>
            </div>
          </div>
          <div className="field">
            <div className="control">
              <button className="button is-primary">Submit</button>
            </div>
          </div>
        </form>
      </div>
    );
  }
}

export default CommentBox;