window.app = {}

CodeMirror.defaults.tabSize = 2
CodeMirror.defaults.indentUnit = 2
CodeMirror.defaults.indentWithTabs = false
CodeMirror.defaults.lineNumbers = true
CodeMirror.defaults.tabMode = 'spaces'
CodeMirror.defaults.extraKeys = {"Tab": "indentMore"}

SyntaxHighlighter.defaults['tab-size'] = 2;
SyntaxHighlighter.defaults['smart-tabs'] = false;
SyntaxHighlighter.all()