import React, { Component } from 'react';
import CommentBox from './CommentBox';
import Comments from './Comments';

class App extends Component {
  constructor(props) {
    super(props);

    this.handleAddComment = this.handleAddComment.bind(this);
    this.state = {
      comments: []
    }
  }

  handleAddComment(comment) {
    this.setState(prevState => {
      return {
        comments: prevState.comments.concat(comment)
      };
    });
  }

  render() {
    return (
      <section className="section">
        <div className="container">
          <div className="columns">
            <div className="column is-half is-offset-one-quarter">
              <CommentBox handleAddComment={this.handleAddComment} />
              <Comments comments={this.state.comments.reverse()} />
            </div>
          </div>
        </div>
      </section>
    );
  }
}

export default App;