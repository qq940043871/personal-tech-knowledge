(function(){ var ua = window.navigator.userAgent; var isAndroid = !!ua.match(/Android/i); var isIPad = !!ua.match(/iPad/i); var isIPhone = !!ua.match(/iPhone/i); var isLinux = !!ua.match(/Linux/i) var isMac = !!ua.match(/Macintosh/i); var clientType = 'windows'; if (isAndroid) { clientType = 'android'; } else if (isIPad || isIPhone) { clientType = 'ios'; } else if (isLinux || isMac) { clientType = 'mac'; } var htmlSrc = ''; var htmlSaveSrc = ''; var hasReplaceEvent = false; var alertLayer = null; var docEventMap = {}; var bodyEventMap = {}; var \_addEventListener; var replaceEvent = function() { // 接管 document.body 的所有事件 if (hasReplaceEvent) return; \_addEventListener = document.body.addEventListener; document.body.addEventListener = (type, fun) => { if (!bodyEventMap\[type\]) { bodyEventMap\[type\] = \[\]; } bodyEventMap\[type\].push(fun); \_addEventListener.apply(document.body, \[type, fun\]); }; document.addEventListener = (type, fun) => { if (!docEventMap\[type\]) { docEventMap\[type\] = \[\]; } docEventMap\[type\].push(fun); \_addEventListener.apply(document, \[type, fun\]); }; hasReplaceEvent = true; }; var clearEvent = function() { // 停止之前注册的 event for (var type in docEventMap) { if (docEventMap.hasOwnProperty(type)) { var funList = docEventMap\[type\]; for (var i=; i<funList.length; i++) { document.removeEventListener(type, funList\[i\]); } } } for (var type in bodyEventMap) { if (bodyEventMap.hasOwnProperty(type)) { var funList = bodyEventMap\[type\]; for (var i=; i<funList.length; i++) { document.body.removeEventListener(type, funList\[i\]); } } } }; var compareVersion = function (v, v) { v = vsplit('.'); v = vsplit('.'); var i, j, n, n; for (i = , j = vlength; i < j; i++) { n = parseInt(v\[i\], ); n = v\[i\] ? parseInt(v\[i\], ) : -; if (n < n) { return -; } else if (n > n) { return ; } } if (vlength < vlength) { return -; } return ; } var fixOutline = function() { var switchList = document.querySelectorAll('.icon-down\_arrow\_small'); var i, dom; for (i = switchList.length -; i>=; i--) { dom = switchList\[i\]; dom.className = dom.className.replace('icon-down\_arrow\_small', 'icon-down\_arrow'); } var nodeList = document.querySelectorAll('.node.collapsed'); for (i = nodeList.length -; i>=; i--) { dom = nodeList\[i\]; dom.className = dom.className.replace('collapsed', ''); } var nightModeStyle = document.getElementById('wiz\_night\_mode\_style'); if (nightModeStyle) { var color = window.getComputedStyle(document.body).color; let s = document.createElement('style'); s.setAttribute('name', 'wiz\_tmp\_editor\_style'); s.innerHTML = '.wiz-editor-body .node .dot-icon {background-color: ' + color + ' !important;}' + '.wiz-editor-body .node .row,' + '.wiz-editor-body .node .dot,' + '.wiz-editor-body .node .content,' + '.wiz-editor-body .node .child,' + '.wiz-editor-body .node .operator-container,' + '.wiz-editor-body .node .operator-bar,' + '.wiz-editor-body .node .row .switch,' + '.wiz-editor-body .node .row .switch i.editor-icon,' + '.wiz-editor-body .node.show-menu .node' + ' {background-color:transparent !important;}' + ''; document.querySelector('HEAD').appendChild(s); } }; var getDependencyUrl = function() { var linkList = document.querySelectorAll('link'); for (var i=; i<linkList.length; i++) { var link = linkList\[i\]; var href = link.href; if (/\\/dependency\\//.test(href)) { var path = href.replace(/^(.\*\\/dependency)\\/.\*$/, '$'); return path; } } return ''; } var removeAlert = function() { if (alertLayer) { document.body.removeChild(alertLayer); alertLayer = null; } }; var checkWizEditorOn = function() { replaceEvent(); // 检测 版本 var minVersion = document.body.getAttribute('data-wiz-document-min-version'); if (!minVersion) {return;} if (window.WizDocument && compareVersion(window.WizDocument.version, minVersion) >= ) { return; } if (!window.WizEditor || !window.WizEditor.on) { setTimeout(checkWizEditorOn, ); return; } setTimeout(function() { if (isAndroid) { htmlSaveSrc = WizEditor.getContentHtml(); } clearEvent(); // 获取 dependence 地址 var dependencyUrl = getDependencyUrl(); var init = WizEditor.init; WizEditor.init = function(options) { if (options && options.reader && options.reader.autoEdit) { options.reader.autoEdit = false; } return init(options); }; WizEditor.init({ document: document, clientType: clientType, dependencyUrl: dependencyUrl, reader: { autoEdit: false, } }); for (var key in WizEditor) { if (WizEditor.hasOwnProperty(key) && !/^(on|version|getContentHtml|insertCustomStyle|insertDefaultStyle|isModified|nightMode)$/.test(key)) { WizEditor\[key\] = function() {}; } } var \_readerOn = WizReader.on; WizReader.on = function(options, callback) { removeAlert(); \_readerOn(options, callback); }; WizEditor.off = WizReader.on; WizEditor.isModified = function() {return false;}; if (isMac || isAndroid) { WizEditor.getContentHtml = function() { if (isMac) return ''; return htmlSaveSrc; }; } WizEditor.on = function(options, callback) { alertLayer = document.createElement('wiz\_tmp\_tag'); alertLayer.setAttribute('style', 'position:fixed;top:;left:;right:;bottom:;margin:;'); var lang = window.navigator.language; var text = '<div>The client is too old. Please update it.</div>'; if (/^zh/i.test(lang)) { text = '<div>客户端版本过低，无法编辑该笔记，请升级为最新版本</div>' + text; } alertLayer.innerHTML = '' + '<div style="margin:;width: %;height: %;background:rgba(, , , ) !important;display:flex;align-items:center;justify-content:center;">' + '<div style="border-radius:px;max-width:%;background:#fff;margin:;padding:px px px;box-sizing:border-box;border: px solid #fff;">' + text + '<div style="text-align:right;">' + '<a id="wiz\_alert\_info" style="color: #aff;">OK</a>' + '</div>' + '</div>' + '</div>'; document.body.appendChild(alertLayer); var closeBtn = alertLayer.querySelector('#wiz\_alert\_info'); if (closeBtn) { closeBtn.addEventListener('click', removeAlert); } \_readerOn(options); if (callback) {callback();} } if (htmlSrc) { document.body.innerHTML = htmlSrc; } fixOutline(); WizReader.on(); }, ); }; document.addEventListener('DOMContentLoaded', function() { if (isAndroid) { htmlSrc = document.body.innerHTML; } checkWizEditorOn(); }); })();

隔离性

Namespace

IPC  System V IPC和POSIX消息队列

Network 网络设备、网络协议栈、网络端口等

PID 进程

Mount 挂载点

UTS 主机名和域名

USR 用户和用户组

lsns 查看当前所有namspace

容器技术只是进程、没有完整的操作系统

nsenter -t pid -n ip a 查看docker网络设置

docker如何建立本地仓库

linux对namespace操作方法

clone

setns

unshare

同一主机ks现在是个

同一主机docker名义上没限制

可配额、可度量

cgroups

可以控制linux各进程cpu消耗的资源

memory子系统

Union FS文件系统

Docker文件系统

bootfs

rootfs

docker inspect

namespace做资源隔离、cgroup做资源控制

Kubernetes的核心组件