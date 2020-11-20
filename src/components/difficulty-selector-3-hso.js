const {
  polymer_ext,
  list_polymer_ext_tags_with_info
} = require('libs_frontend/polymer_utils')

const {
  get_enabled_interventions,
  enabledisable_interventions_based_on_difficulty,
} = require('libs_backend/intervention_utils')

const {
  add_log_interventions,
} = require('libs_backend/log_utils')

const {
  send_feature_option,
} = require('libs_backend/logging_enabled_utils')

const {
  setvar_experiment
} = require('libs_backend/db_utils')

polymer_ext({
  is: 'difficulty-selector-3-hso',
  selectedNudgechanged: async function(evt) {
    /*
    if (this.ignoreselectedchanged == true) {
      return
    }
    */
    //console.log("selected changed");
    //console.log(evt);
    let site = evt.detail.value;
    //console.log(site);
    let stressful = this.value;
    //console.log(stressful);
    let stressful_sites = await localStorage.getItem("stressful_sites");
    //console.log(stressful_sites);
    //console.log(JSON.parse(stressful_sites));
    if (stressful_sites === null) {
      localStorage.setItem("stressful_sites", [site]);
    } else {
      //stressful_sites.push("");
      localStorage.setItem("stressful_sites", JSON.stringify(stressful_sites));
    }
    /*
    let prev_enabled_interventions = await get_enabled_interventions()
    if (localStorage.difficulty_selector_userchoice == 'true') {
      await enabledisable_interventions_based_on_difficulty(difficulty)
    }

    localStorage.user_chosen_difficulty = difficulty
    setvar_experiment('user_chosen_difficulty', difficulty)
    send_feature_option({feature: 'difficuty', page: 'onboarding-view', difficulty: difficulty})
    let log_intervention_info = {
      type: 'difficulty_selector_changed_onboarding',
      difficulty_changes_interventions: false,
      page: 'onboarding-view',
      subpage: 'difficulty-selector-hso',
      category: 'difficulty_change',
      difficulty: difficulty,
      manual: true,
      url: window.location.href,
      prev_enabled_interventions: prev_enabled_interventions,
    }
    await add_log_interventions(log_intervention_info)
    this.fire('difficulty-changed', {difficulty: difficulty})
    */
  },

  ignore_keydown: function(evt) {
    evt.preventDefault();
    //evt.stopPropagation()
    return false;
  },
  add_stressful_site: async function(evt){
    //console.log("User wants to add stressful site");
    var input = this.$.site_input.value;
    var site = "";
    var url_regex = /^(((?:www\.|[\-;:&=\+\$,\w]+@)[A-Za-z0-9\.\-]+)((?:\/[\+~%\/\.\w\-_]*)?\??(?:[\-\+=&;%@\.\w_]*)#?(?:[\.\!\/\\\w]*))?)/;
    // If input empty or input doesn't match format don't add
    if(input == ""){
      alert("No site added. Please add a site in the correct format before submitting.");
    } else if (! url_regex.test(input)) {
      alert("Incorrect format. Please add a site in the correct format before submitting.");
    } else {
      // // Add checkbox with sitename as label and input as value
      // // make sure it is checked
      // // Also add delete option
      // // And add site to stressful sites list with setItem
      //console.log("Adding site: ");
      //console.log(input);
      var sitename = input.split(".")[1];
      //console.log(sitename);
      var stressful_sites = JSON.parse( await localStorage.getItem("stressful_sites"));
      //console.log(stressful_sites);
      if (stressful_sites === null) {
        localStorage.setItem("stressful_sites", [input]);
      } else {
        stressful_sites.push(input);
        localStorage.setItem("stressful_sites", JSON.stringify(stressful_sites));
      }
      var checkbox_list = document.getElementById('stressful_sites_boxes'); //ul
      var li = document.createElement('li');//li

      var checkbox = document.createElement('paper-checkbox');
          checkbox.type = "checkbox";
          checkbox.value = sitename;
          checkbox.name = "button";
          checkbox.checked = true;
          //checkbox.classList.add('checkbox_class');
      li.classList.add('added_site_button');
      li.appendChild(checkbox);
      li.appendChild(document.createTextNode(sitename));

      checkbox_list.appendChild(li);

    }
  },

  ready: async function(evt) {
    //if (localStorage.user_chosen_difficulty != null) {
      //await once_available('')
      /*
      this.ignoreselectedchanged = true
      await this.once_available('#difficultyradiogroup')
      this.$$('#difficultyradiogroup').selected = localStorage.user_chosen_difficulty
      this.ignoreselectedchanged = false
      */
  //  }
  }

}, {
  source: require('libs_frontend/polymer_methods'),
  methods: [
    'once_available'
  ]
});
