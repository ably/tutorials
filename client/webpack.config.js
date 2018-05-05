const path = require('path');
const { VueLoaderPlugin } = require('vue-loader')

const distPath = path.resolve(__dirname, '../server/public');

module.exports = {
  mode: 'development',
  output: {
    path: distPath
  },
  resolve: {
    alias: {
      'vue$': 'vue/dist/vue.esm.js'
    },
    extensions: ['*', '.js', '.vue', '.json']
  },
  module: {
    rules: [
      { test: /\.vue$/, loader: 'vue-loader' },
      { test: /\.css$/, use: ['vue-style-loader', 'css-loader'] }
    ],
  },
  devServer: {
    contentBase: distPath,
    port: 9000,
    historyApiFallback: true,
    proxy: {
      '/auth': 'http://localhost:3000'
    },
  },
  plugins: [
    new VueLoaderPlugin()
  ]
}