import { Controller } from "@hotwired/stimulus";
import autoComplete from "@tarekraafat/autocomplete.js";

export default class extends Controller {
  static targets = ["button"];

  enable() {
    this.buttonTarget.disable = false;
    this.buttonTarget.classList.remove("opacity-40");
    this.buttonTarget.classList.add("hover:opacity-80");
  }
}
