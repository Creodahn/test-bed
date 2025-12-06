import { debounce, next } from '@ember/runloop';
import { fn, hash } from '@ember/helper';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';
import Component from '@glimmer/component';
import styles from './radio-knob.module.css';

const knob = class InputRadioKnobKnob extends Component {
  @tracked _angle = 0;

  get activeOption() {
    return (this.angle / this.shiftAngle) % this.args.optionCount;
  }

  get angle() {
    return this._angle;
  }

  set angle(change) {
    return this._angle += change;
  }

  get shiftAngle() {
    return this.args.angle;
  }

  get size() {
    return this.args.size * .60;
  }

  get styles() {
    return htmlSafe(`transform: rotateZ(${this.angle}deg)`);
  }

  updateAngleFromOutside = modifier(() => {
    let { activeOption } = this.args;

    if ([undefined, null, this.activeOption].includes(activeOption)) return;

    next(this, () => {
      this.angle = (this.shiftAngle * activeOption) - this.angle;
    });
  })

  click = (...args) => {
    // event is always the last item passed
    let evt = args.pop();

    evt.preventDefault();

    // if it's a right click, we'll get a value, otherwise undefined
    this.updateAngle(args.pop());

    this.args.onClick?.(this.activeOption);
  };

  updateAngle = (modifier = 1) => {
    this.angle = this.shiftAngle * modifier;
  }

  <template>
    <div class={{styles.knob-container}} {{this.updateAngleFromOutside}}>
      <button
        class={{styles.knob}}
        style={{this.styles}}
        type="button"
        {{on "click" this.click}}
        {{on "contextmenu" (fn this.click -1)}}
      />
    </div>
  </template>
};

const option = class InputRadioKnobOption extends Component {
  @tracked position;

  constructor() {
    super(...arguments);

    this.position = this.args.register(this);
  }

  get angle() {
    return this.args.angle;
  }

  get isActive() {
    return this.position === this.args.activeOption;
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

  calculatePosition = modifier(element => {
    this.#registerElements(element);

    if (this.angle >= 360) return;

    this.#calculatePosition();
  });

  #calculatePosition = () => {
    let { radius, size, specificAngle } = this;
    let rad = specificAngle * Math.PI / 180;
    let x = Math.ceil(radius - radius * Math.sin(rad));
    let y = Math.ceil(radius + radius * Math.cos(rad));
    let { modifiedX, modifiedY } = this.modifyCoordinates(x, y);

    if (x > 180) this.span.classList.add(styles['invert-padding']);
    if (y > 180) this.span.classList.add(styles['top-border']);

    this.el.style.left = modifiedX;
    this.el.style.top = modifiedY;
  };

  #registerElements = element => {
    this.el = element;
    this.span = this.el.querySelector('span');
  }

  // modify coordinates to take height and width into account based on position in circle
  modifyCoordinates = (x, y) => {
    let { height, width } = this.el.getBoundingClientRect();
    let modifiedHeight = y < 180 ? -1 * height : 0;
    let modifiedWidth = x < 180 ? -1 * width : 0 ;
    let modifiedX = x + modifiedWidth;
    let modifiedY = y + modifiedHeight;

    return { modifiedX: `${modifiedX}px`, modifiedY: `${modifiedY}px` };
  };

  <template>
    <label class={{styles.option}} {{this.calculatePosition}} {{on "click" (fn @onClick this.position)}}>
      <span>{{yield}}</span>
      <input checked={{this.isActive}} name={{@group}} type="radio" />
    </label>
  </template>
};

export default class InputRadioKnob extends Component {
  #options = [];

  @tracked activeOption = 0;
  @tracked options = [];

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

  get sizePx() {
    return `${this.size}px`;
  }

  setupContainer = modifier(element => {
    element.style.setProperty('--size', this.sizePx);
  });

  handleClick = option => {
    this.activeOption = option;
  };

  registerOption = option => {
    let index = this.#options.push(option) - 1;

    debounce(this, this.updateOptions, 1);

    return index;
  };

  updateOptions = () => {
    this.options = this.#options;
  };

  <template>
    <div class={{styles.radio-knob-container}} {{this.setupContainer}}>
      {{yield
        (hash
          knob=(component knob
            activeOption=this.activeOption
            angle=this.angle
            onClick=this.handleClick
            optionCount=this.optionCount
          )
          option=(component option
            activeOption=this.activeOption
            angle=this.angle
            group=this.group
            onClick=this.handleClick
            register=this.registerOption
            size=this.size
          )
        )
      }}
    </div>
  </template>
}
