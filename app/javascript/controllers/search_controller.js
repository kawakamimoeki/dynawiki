import { Controller } from "@hotwired/stimulus";
import autoComplete from "@tarekraafat/autocomplete.js";

export default class extends Controller {
  static values = {
    list: Array,
  };

  connect() {
    this.autoCompleteJS = new autoComplete({
      placeHolder: "Search or Create",
      data: {
        src: this.listValue.map((i) => i.title),
      },
      resultItem: {
        highlight: true,
      },
      searchEngine: "loose",
      submit: true,
    });

    document
      .querySelector("#autoComplete")
      .addEventListener("selection", function (event) {
        event.target.value = event.detail.selection.value;
      });

    document.querySelector("form").addEventListener("submit", this.encode);
  }

  encode(event) {
    event.target.value = event.target.value;
  }
}
