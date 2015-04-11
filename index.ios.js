// WebView component that takes HTML strings and sanitises them to
// remove javascript and any other dangerous tags. Link clicks will
// generate events but won't automatically change what is displayed.

var React = require('react-native');
var {
  View,
  PropTypes
} = React;

var safeHtml = require('safe-html');
var _ = require('underscore');

var createReactIOSNativeComponentClass = require('createReactIOSNativeComponentClass');

var _HTMLWebView = createReactIOSNativeComponentClass({
  validAttributes: {html: true, enableScroll: true},
  uiViewClassName: 'AIBHTMLWebView'
})


var HTMLWebView = React.createClass({
  propTypes: {
    html: PropTypes.string.isRequired,
    makeSafe: PropTypes.object,
    onLink: PropTypes.func,
    style: View.propTypes.style,
    // Should this view adjust its height automatically to show its
    // complete content
    autoHeight: PropTypes.bool
  },

  getInitialState: function() {
    return {
      contentHeight: 1
    };
  },

  render: function () {
    return (
        <_HTMLWebView
          style={[{height: this.state.contentHeight}, this.props.style]}
          html={this.safeHtml(this.props.html)}
          enableScroll={!this.props.autoHeight}
          onLink={this.onLink}
          onContentHeight={this.onContentHeight}
        />
    );
  },

  safeHtml: function (html) {
    var config = this.props.makeSafe;
    if (config === false) {
      // saveHtml disabled
      return html;
    } else if (!_.isObject(config)) {
      config = module.exports.HTML_SAFE_CONFIG;
    }
    return safeHtml(html, config);
  },

  onLink: function (e) {
    if (_.isFunction(this.props.onLink)) {
      this.props.onLink(e.nativeEvent.url);
    }
  },

  onContentHeight: function (e) {
    if (e.nativeEvent.contentHeight > 1 && this.props.autoHeight && e.nativeEvent.contentHeight !== this.state.contentHeight) {
      this.setState({contentHeight: e.nativeEvent.contentHeight});
    }
  }
});

module.exports = HTMLWebView;

// Allow a few more things than the default config for safe-html since
// we know where it's going to be used.
module.exports.HTML_SAFE_CONFIG = _.defaults(
  {
    allowedTags: safeHtml.DEFAULT_CONFIG.allowedTags.concat(["img", "style"]),
    allowedAttributes: _.defaults(
      {
        id: {allTags: true},
        style: {allTags: true},
        src: {allowedTags: ["img"]}
      }, safeHtml.DEFAULT_CONFIG.allowedAttributes)
  },
  safeHtml.DEFAULT_CONFIG
);
