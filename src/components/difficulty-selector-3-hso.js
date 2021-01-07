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
  properties: {
    stressful_array: {
      type: Array,
      value: []
    }
  },
  selectedNudgechanged: async function(evt) {
    /*
    if (this.ignoreselectedchanged == true) {
      return
    }
    */

    let site = evt.target.value.toString();
    let in_list = evt.target.checked;
    console.log(site);
    console.log(this.stressful_array);
    if (in_list){
      console.log("adding site");
      this.stressful_array.push(site);
    } else {
      console.log("removing site");
      console.log(this.stressful_array);
      var index = this.stressful_array.indexOf(site);
      if (index > -1) {
        this.stressful_array.splice(index, 1);
      }
    }
    console.log(this.stressful_array);
    localStorage.setItem("stressful_sites", this.stressful_array);
  },

  ignore_keydown: function(evt) {
    evt.preventDefault();
    //evt.stopPropagation()
    return false;
  },

  add_stressful_site: async function(evt){
    //console.log("User wants to add stressful site");
    var input = this.$.site_input.value;
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
      /*
      var stressful_sites = JSON.parse( await localStorage.getItem("stressful_sites"));
      //console.log(stressful_sites);
      if (stressful_sites === null) {
        localStorage.setItem("stressful_sites", [input]);
      } else {
        stressful_sites.push(input);
        localStorage.setItem("stressful_sites", JSON.stringify(stressful_sites));
      }
      */
      const index = this.stressful_array.indexOf(input);
      // If not already in index
      if (index == -1){
        this.stressful_array.push(input);
        var checkbox_list = document.getElementById('stressful_sites_boxes'); //ul
        var li = document.createElement('li');//li

        var checkbox = document.createElement('paper-checkbox');
            checkbox.type = "checkbox";
            checkbox.value = input;
            checkbox.name = "button";
            checkbox.checked = true;
            checkbox.onchange = this.selectedNudgechanged;
            //checkbox.classList.add('checkbox_class');
        li.classList.add('added_site_button');
        li.appendChild(checkbox);
        li.appendChild(document.createTextNode(input));

        checkbox_list.appendChild(li);
      }
      localStorage.setItem("stressful_sites", this.stressful_array);
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
