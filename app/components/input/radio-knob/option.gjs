import { on } from '@ember/modifier';
import { registerDestructor } from '@ember/destroyable';
import { tracked } from '@glimmer/tracking';
import Core from '../../core';
import styles from './option.module.css';

export default class InputRadioKnobOption extends Core {
  #setupRun = false;
  baseClass = styles.option;
  classesToMap = ['bottom-border', 'invert-padding', 'top-border'];
  elementsToRegister = [{ selector: 'input' }, { selector: 'span' }];
  propsToMap = ['x', 'y'];
  styles = styles;

  @tracked isActive = false;
  @tracked position;
  @tracked x;
  @tracked y;

  constructor() {
    super(...arguments);

    this.position = this.args.register(this);

    registerDestructor(this, () => {
      this.args.unregister(this);
    });
  }

  get angle() {
    return this.args.angle;
  }

  get bottomBorder() {
    return !this.topBorder;
  }

  get invertPadding() {
    return this.x > 180;
  }

  get label() {
    return this.span?.innerText?.trim()
  }

  get radius() {
    return this.size / 2;
  }

  get size() {
    return this.args.size;
  }

  get specificAngle() {
    // flip angle to be on opposite side to match neutral knob position
    return this.angle * this.position + 180;
  }

  get topBorder() {
    return this.y > 180;
  };

  #calculatePosition = () => {
    let { radius, specificAngle } = this;
    let rad = specificAngle * Math.PI / 180;
    let initX = Math.ceil(radius - radius * Math.sin(rad));
    let initY = Math.ceil(radius + radius * Math.cos(rad));

    this.modifyCoordinates(initX, initY);
  };

  // modify coordinates to take height and width into account based on position in circle
  modifyCoordinates = (x, y) => {
    let { height, width } = this.baseElement.getBoundingClientRect();
    let modifiedHeight = y < 180 ? -1 * height : 0;
    let modifiedWidth = x < 180 ? -1 * width : 0 ;

    this.x = x + modifiedWidth;
    this.y = y + modifiedHeight;
  };

  click = () => {
    this.isActive = this.input.checked = true;
    this.args.onActiveChange?.();
  }

  setup = () => {
    if (this.#setupRun || this.angle >= 360) return;

    this.#calculatePosition();
    this.#setupRun = true;
  }

  <template>
    <label
      class={{styles.option}}
      data-position={{this.position}}
      style={{this.props}}
      {{this.calculatePosition}}
      {{this.setupComponent}}
      {{on "click" this.click}}
    >
      <span class={{this.classes}}>{{yield}}</span>
      <input
        name={{@group}}
        type="radio"
        {{this.trackInputChange}}
        ...attributes
      />
    </label>
  </template>
};
