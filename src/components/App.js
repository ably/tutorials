import React, { Component } from 'react';
import CommentBox from './CommentBox';
import Comments from './Comments';
import Ably from '../ably';

class App extends Component {
  constructor(props) {
    super(props);

    this.state = {
        comments: []
    }
  }

  componentDidMount() {
    // Subscribe to comments
    const channel = Ably.channels.get('comments');
    channel.subscribe('add_comment', (comment) => {
      this.setState((prevState) => {
        return {
          comments: prevState.comments.concat({
            name: comment.data.name,
            comment: comment.data.comment
          })
        };
      });
    });
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
    );
  }
}

export default App;
