import { Controller } from "@hotwired/stimulus";
import autoComplete from "@tarekraafat/autocomplete.js";

export default class extends Controller {
  static values = {
    list: Array,
    name: String,
  };

  connect() {
    const config = {
      placeHolder: "What do you want to know?",
      data: {
        src: this.listValue.map((i) => i.title),
      },
      resultItem: {
        highlight: true,
      },
      searchEngine: "loose",
      submit: true,
    };
    this.autoCompleteJS = new autoComplete({
      name: this.nameValue,
      selector: `#${this.nameValue}`,
      ...config,
    });

    document
      .querySelector(`#${this.nameValue}`)
      .addEventListener("selection", function (event) {
        event.target.value = event.detail.selection.value;
      });

    document.querySelector("form").addEventListener("submit", this.encode);
  }

  encode(event) {
    event.target.value = event.target.value;
  }
}
