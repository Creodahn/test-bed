import { debounce } from '@ember/runloop';
import { hash } from '@ember/helper';
import { tracked } from '@glimmer/tracking';
import Core from '../core';
import Knob from './radio-knob/knob.gjs';
import Option from './radio-knob/option';
import styles from './radio-knob.module.css';

export default class InputRadioKnob extends Core {
  #options = [];
  baseClass = styles['radio-knob-container'];
  propsToMap = ['size'];

  @tracked options = [];
  @tracked activeOption = 0;

  get angle() {
    return 360 / this.optionCount;
  }

  get group() {
    return this.args.group ?? 'radio-knob';
  }

  get optionCount() {
    return this.options.length || 1;
  }

  get size() {
    return this.args.size ?? 500;
  }

  registerOption = option => {
    let index = this.#options.push(option) - 1;

    debounce(this, this.updateOptions, 1);

    return index;
  };

  unregisterOption = option => {
    this.#options = this.#options.filter(opt => opt !== option);

    debounce(this, this.updateOptions, 1);
  };

  updateActiveOption = () => {
    let active = this.options.findIndex(option => option?.input?.checked);

    if (active === -1) {
      active += this.options.length;;
      this.options[active].input.checked = true;
    }


    if (active !== this.activeOption) {
      this.activeOption = active;
    }
  };

  updateFromKnob = activeOption => {
    let option = this.options[activeOption];

    if (option) {
      option.input.checked = true;
      this.updateActiveOption();
    }
  };

  updateOptions = () => {
    this.options = this.#options;
    this.updateActiveOption();
  };

  <template>
    <div class={{this.classes}} style={{this.props}} {{this.setupContainer}}>
      {{yield
        (hash
          knob=(component Knob
            activeOption=this.activeOption
            angle=this.angle
            onClick=this.updateFromKnob
            optionCount=this.optionCount
            size=this.size
          )
          option=(component Option
            angle=this.angle
            group=this.group
            onActiveChange=this.updateActiveOption
            register=this.registerOption
            size=this.size
            unregister=this.unregisterOption
          )
        )
      }}
    </div>
  </template>
}
