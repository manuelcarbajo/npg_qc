"use strict";
require.config({
  baseUrl: '../../root/static',
  paths: {
    jquery: 'bower_components/jquery/dist/jquery',
  },
});

require(['scripts/qc_css_styles'],
  function(qc_css_styles) {

    var TestConfiguration = (function() {
      function TestConfiguration () {
      }

      TestConfiguration.prototype.getRoot = function() {
        return './';
      };

      return TestConfiguration;
    }) ();

    NPG.QC.qc_css_styles = qc_css_styles;

    QUnit.test("DOM linking", function( assert ) {
      var lane = $("#mqc_lane1");
      assert.notEqual(lane, undefined, "mqc_lane is an instance.");
      assert.equal(lane.data('id_run'), '2', "id_run is 2.");
      assert.equal(lane.data('position'), '3', "position is 3.");
      assert.equal(lane.data('initial'), undefined, "No initial value.");
      var control = new NPG.QC.LaneMQCControl(new TestConfiguration());
      assert.notEqual(control, undefined, "Control is an instance.");
      control.linkControl(lane);
      assert.notEqual(control.lane_control, undefined, "lane_control in Control is linked.");
      assert.equal(control.lane_control, lane, "Control and lane are correctly linked.");
      assert.equal(control.lane_control.outcome, undefined, "Outcome of lane is not defined.");
    });

    QUnit.test("DOM linking lane with previous status", function( assert ) {
      var lane = $("#mqc_lane2");
      assert.notEqual(lane, undefined, "mqc_lane is an instance.");
      assert.equal(lane.data('id_run'), '3', "id_run is 3.");
      assert.equal(lane.data('position'), '4', "position is 4.");
      assert.notEqual(lane.data('initial'), undefined, "Has initial value.");
      assert.equal(lane.data('initial'), 'Accepted final', "Initial value as expected.");
      var control = new NPG.QC.LaneMQCControl(new TestConfiguration());
      assert.notEqual(control, undefined, "Control is an instance.");
      control.linkControl(lane);
      assert.notEqual(control.lane_control, undefined, "lane_control in Control is linked.");
    });

    QUnit.test("NPG.QC.RunPageMQCControl.initQC", function(assert) {
      var data1 = null;
      var control = new NPG.QC.RunPageMQCControl(new TestConfiguration());
      var returnTrue = function () { return true; };
      var returnFalse = function () { return false; };
      var result1 = control.initQC(data1, null, returnTrue, returnFalse);
      assert.equal(result1, false, 'Control can deal with null data object.');
      data1 = new Object();
      var result2 = control.initQC(data1, null, function () {return true}, function(){return false});
      assert.equal(result2, false, 'Control can deal with empty data object');
      data1.taken_by = 'me';
      data1.current_user = 'me';
      data1.has_manual_qc_role = 1;
      data1.current_status_description = 'qc in progress';
      var result3 = control.initQC(data1, null, function () {return true}, function() {return false});
      assert.equal(result3, true, 'Completes with correct data (qc in progress)');
      data1.current_status_description = 'qc on hold';
      var result31 = control.initQC(data1, null, function () {return true}, function() {return false});
      assert.equal(result31, true, 'Completes with correct data (qc on hold)');
      //
      data1.taken_by = 'other';
      var result4 = control.initQC(data1, null, function () {return true}, function() {return false});
      assert.equal(result4, false, 'Does not run if taken by and current user are different');
      data1.taken_by = 'me';
      //
      data1.current_user = 'other';
      var result5 = control.initQC(data1, null, function () {return true}, function() {return false});
      assert.equal(result5, false, 'Does not run if current user and taken by are different');
      data1.current_user = 'me';
      //
      data1.has_manual_qc_role = '';
      var result6 = control.initQC(data1, null, function () {return true}, function() {return false});
      assert.equal(result6, false, 'Does not run if has manual qc role is not available');
      data1.has_manual_qc_role = 1;
      //
      data1.current_status_description = 'blablabla';
      var result7 = control.initQC(data1, null, function () {return true}, function() {return false});
      assert.equal(result7, false, 'Does not run if current status description is a unexpected one');
      data1.current_status_description = 'qc in progress';
    });

    QUnit.test("NPG.QC.RunPageMQCControl.isStateForMQC", function(assert){
      var result = null;

      var TAKEN_BY = 'taken_by';
      var CURRENT_USER = 'current_user';
      var HAS_MANUAL_QC_ROLE = 'has_manual_qc_role';
      var CURRENT_STATUS_DESCRIPTION = 'current_status_description';

      var control = new NPG.QC.RunPageMQCControl(new TestConfiguration());
      var ok_taken_by = 'me', ok_current_user = 'me';
      var ok_has_manual_qc_role = 1;
      var ok_current_status_description_1 = 'qc in progress', ok_current_status_description_2 = 'qc on hold';

      var createFullObject = function () {
        var theObject = new Object();

        theObject[TAKEN_BY] = ok_taken_by;
        theObject[CURRENT_USER] = ok_current_user;
        theObject[HAS_MANUAL_QC_ROLE] = ok_has_manual_qc_role;
        theObject[CURRENT_STATUS_DESCRIPTION] = ok_current_status_description_1;

        return theObject;
      };

      assert.raises(function () { control.isStateForMQC() }, /Error: Invalid arguments/, 'Correctly validates it gets an argument');
      assert.raises(function () { control.isStateForMQC(null) }, /Error: Invalid arguments/, 'Correctly validates it gets an non-null argument');
      var mqc_run_data = Object();
      result = control.isStateForMQC(mqc_run_data);
      assert.equal(result, false, 'Correctly evaluates for an empty data object.');

      mqc_run_data = createFullObject();
      assert.equal(control.isStateForMQC(mqc_run_data), true, 'Correctly evaluates for a full object.');

      mqc_run_data[CURRENT_STATUS_DESCRIPTION] = ok_current_status_description_2;
      assert.equal(control.isStateForMQC(mqc_run_data), true, 'Correctly evaluates for a full object different current_status_description.');

      var all_names = [TAKEN_BY, CURRENT_USER, HAS_MANUAL_QC_ROLE, CURRENT_STATUS_DESCRIPTION];
      for(var i = 0; i < all_names.length; i++) {
        mqc_run_data = createFullObject();
        mqc_run_data[all_names[i]] = null;
        assert.equal(control.isStateForMQC(mqc_run_data), false, 'Correctly evaluates for a full object with null in ' + all_names[i]);
      }

      for(var i = 0; i < all_names.length; i++) {
        mqc_run_data = createFullObject();
        mqc_run_data[all_names[i]] = 'xxxxxx';
        assert.equal(control.isStateForMQC(mqc_run_data), false, 'Correctly evaluates for a full object with incorrect value in ' + all_names[i]);
      }
    });

    QUnit.test("NPG.QC.RunPageMQCControl.prepareLanes", function(assert) {
      var control = new NPG.QC.RunPageMQCControl(new TestConfiguration());
      assert.raises(function () {control.prepareLanes();}, /Error: Invalid arguments/, "Throws exception with invalid number of arguments");
      assert.raises(function () {control.prepareLanes(null, null);}, /Error: Invalid arguments/, "Throws exception with both arguments null");
      assert.raises(function () {control.prepareLanes(null, 1);}, /Error: Invalid arguments/, "Throws exception with first argument null");
      assert.raises(function () {control.prepareLanes(1, null);}, /Error: Invalid arguments/, "Throws exception with second argument null");

    });

    QUnit.test("NPG.QC.RunTitleParser.parseRunId()", function(assert) {
      var parser = new NPG.QC.RunTitleParser();
      assert.throws(function() {parser.parseIdRun();}, /Error: Invalid arguments/, "Validates non-empty arguments");
      assert.throws(function() {parser.parseIdRun(null);}, /Error: Invalid arguments/, "Validates null argument");
      var title1 = parser.parseIdRun('');
      assert.equal(title1, null, 'Can deal with empty string.');
      var title2 = parser.parseIdRun('Bla bla bla');
      assert.equal(title2, null, 'Can deal with random string');
      var title3 = parser.parseIdRun('NPG SeqQC v56.7: Results for run number (current run status: qc in progress, taken by user)');
      assert.equal(title3, null, 'Can deal with non valid run_id (lexical validation)');
      var title4 = parser.parseIdRun('NPG SeqQC v56.7: Results for run (current run status: qc in progress, taken by user)');
      assert.equal(title4, null, 'Can deal with missing run_id (lexical validation)');
      var title5 = parser.parseIdRun('NPG SeqQC v56.7: Results for run 16074 (current run status: qc in progress, taken by user)');
      assert.equal(title5.id_run, '16074', 'Correctly parses run_id from correctly formed title');
      var title6 = parser.parseIdRun('NPG SeqQC v56.7: Results for run 16074 (current run status: ');
      assert.equal(title6.id_run, '16074', 'Correctly parses run_id from non qc title');
      assert.equal(title6.position, null, 'Correctly sets position as null');
      assert.ok(title6.isRunPage, 'Correctly identifies the page as a single run page');
      var title7 = parser.parseIdRun('NPG SeqQC v56.7: Results (all) for runs 16074 lanes 1');
      assert.equal(title7.id_run, '16074', 'Correctly parses run_id and position from non qc title');
      assert.equal(title7.position, '1', 'Correctly sets position as 1');
      assert.ok(!title7.isRunPage, 'Correctly identifies the page as a run + lane page');
      var title8 = parser.parseIdRun('NPG SeqQC v56.7: Results (all) for runs 16074 lanes 1 2');
      assert.equal(title8, null, 'Can deal with multi lane pages (lexical validation)');
      var title9 = parser.parseIdRun('NPG SeqQC v56.7: Results (all) for runs 16074 16075 lanes 1');
      assert.equal(title9, null, 'Can deal with multi run pages (lexical validation)');
      var title10 = parser.parseIdRun('NPG SeqQC v56.7: Results (all) for runs 16074 16075 lanes 1 2');
      assert.equal(title10, null, 'Can deal with multi run, multi lane pages (lexical validation)');
    });

    QUnit.test('Object initialisation', function() {
      var obj = null;
      ok(obj == null, "Variable is initially null.");
      obj = new NPG.QC.LaneMQCControl();
      ok(obj !== undefined, "Variable is now an instance.");
      obj = new NPG.QC.LaneMQCControl(new TestConfiguration());
      ok(obj !== undefined, "Variable is now a new instance called with parameter for constructor.");
      ok(obj.lane_control == null, "New object has null lane_control.");
      ok(obj.abstractConfiguration !== undefined, 'Object has a configuration');
      ok(obj.outcome == null, "New object has null outcome.");

      obj = null;
      ok(obj == null, "Variable back to null.");
      obj = new NPG.QC.LibraryMQCControl();
      ok(obj !== undefined, "Variable is now an instance.");
      obj = new NPG.QC.LibraryMQCControl(new TestConfiguration());
      ok(obj !== undefined, "Variable is now a new instance called with parameter for constructor.");
      ok(obj.lane_control == null, "New object has null lane_control.");
      ok(obj.abstractConfiguration !== undefined, 'Object has a configuration');
      ok(obj.outcome == null, "New object has null outcome.");

      obj = null;
      ok(obj == null, "Variable back to null.");
      obj = new NPG.QC.RunPageMQCControl();
      ok(obj !== undefined, 'variable is now an instance of RunPageMQCControl');
      obj = new NPG.QC.RunPageMQCControl(new TestConfiguration());
      ok(obj !== undefined, 'variable is now an instance of RunPageMQCControl');

      obj = null;
      ok(obj == null, "Variable back to null.");
      obj = new NPG.QC.LanePageMQCControl();
      ok(obj !== undefined, 'variable is now an instance of LanePageMQCControl');
      obj = new NPG.QC.LanePageMQCControl(new TestConfiguration());
      ok(obj !== undefined, 'variable is now an instance of LanePageMQCControl');

      obj = new NPG.QC.RunTitleParser();
      ok(obj !== undefined, 'variable is now an instance of RunTitleParser');
    });

    QUnit.test('Object instantiation for UI classes.', function() {
      var obj = null;

      obj = new NPG.QC.UI.MQCOutcomeRadio();
      ok(obj !== undefined, 'Variable is now an instance of MQCOutcomeRadio');
      obj = null;
      ok(obj == null);

      obj = new NPG.QC.UI.MQCLibraryOverallControls();
      ok(obj !== undefined, 'Variable is now an instance of MQCLibraryOverallControls');
      obj = null;
      ok(obj == null);

      obj = new NPG.QC.UI.MQCLibrary4LaneStats();
      ok(obj !== undefined, 'Variable is now an instance of MQCLibrary4LaneStats');
    });

    QUnit.test('Error messaging formating', function (assert) {
      var obj = null;

      var FROM_EXCEPTION = 'Error: No LIMS data for this run/position. at /src/../lib/npg_qc_viewer/Controller.pm line 1000.';
      var EXPECTED_FE    = 'Error: No LIMS data for this run/position.';
      var FROM_GNR_TEXT  = 'A random error in the interface. And some more text. No numbers should be removed 14.';
      var EXPECTED_GT    = FROM_GNR_TEXT;

      obj = new NPG.QC.UI.MQCErrorMessage(FROM_EXCEPTION);
      assert.equal(obj.formatForDisplay(), EXPECTED_FE, 'Correctly parses from exception');
      obj = new NPG.QC.UI.MQCErrorMessage(FROM_GNR_TEXT);
      assert.equal(obj.formatForDisplay(), EXPECTED_GT, 'Correctly parses from general text');
    });

    // run the tests.
    QUnit.start();
  }
);


