// Generated by CoffeeScript 1.10.0
(function() {
  var assertionTemplate, failedTests, failureTemplate, findElementForTest, fixBrokenThrowsOperatorData, idOfCurrentlyRunningTest, insertFailure, insertTestAssertion, insertTestElement, numberOfFailedTests, numberOfTests, renderBodyElement, renderTestElementEnded, renderTestElementUpdate, testTemplate, untouched,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  module.exports = require("tape").createHarness();

  testTemplate = document.getElementById("test_template");

  failureTemplate = document.getElementById("failure_template");

  assertionTemplate = document.getElementById("assertion_template");

  numberOfTests = document.getElementById("number_of_tests");

  numberOfFailedTests = document.getElementById("number_of_failed_tests");

  idOfCurrentlyRunningTest = void 0;

  untouched = true;

  failedTests = [];

  module.exports.createStream({
    objectMode: true
  }).on("data", function(data) {
    var element;
    switch (false) {
      case data.type !== "test":
        idOfCurrentlyRunningTest = data.id;
        insertTestElement(data);
        return renderBodyElement(data);
      case data.operator == null:
        fixBrokenThrowsOperatorData(data);
        if (data.ok === false) {
          if (indexOf.call(failedTests, idOfCurrentlyRunningTest) < 0) {
            failedTests.push(idOfCurrentlyRunningTest);
          }
        }
        element = findElementForTest(idOfCurrentlyRunningTest);
        renderTestElementUpdate(element, data);
        insertTestAssertion(element, data);
        if (!data.ok) {
          return insertFailure(element, data);
        }
        break;
      case data.type !== "end":
        idOfCurrentlyRunningTest = void 0;
        renderTestElementEnded(findElementForTest(data.test), data);
        if (failedTests.length !== 0) {
          numberOfFailedTests.innerText = failedTests.length;
        }
        numberOfTests.innerText = data.test;
        return renderBodyElement(data);
      default:
        return console.info("Unhandled", data);
    }
  });

  window.onmousewheel = function() {
    delete window.onmousewheel;
    return untouched = false;
  };

  renderBodyElement = function(data) {
    var body;
    body = document.body;
    body.className = body.className.replace("undefined", "");
    body.className = (function() {
      switch (false) {
        case data.type !== "test":
          return body.className.replace("stopped", "running");
        case data.type !== "end":
          return body.className.replace("running", "stopped");
        default:
          return body.className;
      }
    })();
    if (failedTests.length === 1 && body.className.indexOf("fail") === -1) {
      return body.className += " failures";
    }
  };

  insertTestElement = function(data) {
    var bodyHeight, container, containerHeight, element;
    element = testTemplate.cloneNode(true);
    element.id = "test_" + data.id;
    element.querySelector(".name").innerText = data.name;
    element.className += " started";
    element.startedAt = Date.now();
    element.querySelector("div.id").innerText = (data.id / 1000).toFixed(3).replace("0.", "#");
    container = document.getElementById('tests');
    container.appendChild(element);
    containerHeight = parseInt(getComputedStyle(container)['height']);
    bodyHeight = parseInt(getComputedStyle(document.body)['height']);
    if (containerHeight > bodyHeight) {
      document.body.style.height = containerHeight + "px";
    }
    if (untouched) {
      return element.scrollIntoView();
    }
  };

  renderTestElementUpdate = function(element, data) {
    var className;
    className = data.ok ? "ok" : "failed";
    return element.className = element.className.replace(className, "").trim() + " " + className;
  };

  renderTestElementEnded = function(element, data) {
    element.className = element.className.replace("started", "ended");
    return element.querySelector("div.duration").innerText = (((Date.now() - element.startedAt) / 1000).toFixed(2)) + "s";
  };

  insertTestAssertion = function(element, data) {
    var assertionEl;
    assertionEl = assertionTemplate.cloneNode(true);
    assertionEl.id = "test_" + idOfCurrentlyRunningTest + "_assertion_" + data.id;
    element.className = element.className.replace('empty', '').trim();
    return element.querySelector('.assertions').appendChild(assertionEl);
  };

  insertFailure = function(element, data) {
    var failureEl;
    failureEl = failureTemplate.cloneNode("true");
    failureEl.id = "";
    if (typeof data.expected === "function") {
      failureEl.querySelector("pre.expected").innerHTML += data.expected;
    } else {
      failureEl.querySelector("pre.expected").innerHTML += JSON.stringify(data.expected, void 0, "  ");
    }
    if (typeof data.actual === "function") {
      failureEl.querySelector("pre.received").innerHTML += data.actual;
    } else {
      failureEl.querySelector("pre.received").innerHTML += JSON.stringify(data.actual, void 0, "  ");
    }
    if (data.error != null) {
      failureEl.querySelector("pre.error_stack").innerText = data.error.stack;
    }
    element.appendChild(failureEl);
    if ((failedTests.length === 1) && untouched) {
      untouched = false;
      return setTimeout((function() {
        return element.scrollIntoView(true);
      }), 1);
    }
  };

  fixBrokenThrowsOperatorData = function(data) {
    if ((data.operator === "throws") && (data.name !== data.actual)) {
      data.ok = false;
      data.expected = data.name;
      data.name = void 0;
      return data.fixedForThrowsOperator = true;
    }
  };

  findElementForTest = function(id) {
    return document.getElementById("test_" + id);
  };

}).call(this);
