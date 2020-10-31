import React, { Component } from 'react';
import CommentBox from './CommentBox';
import Comments from './Comments';

class App extends Component {
  constructor(props) {
    super(props);

    this.state = {
      comments: []
    }
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
