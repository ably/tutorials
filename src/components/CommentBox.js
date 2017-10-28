import React, { Component } from 'react';
import Ably from '../ably';

class CommentBox extends Component {
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