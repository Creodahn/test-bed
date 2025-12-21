import { fn } from '@ember/helper';
import { modifier } from 'ember-modifier';
import { next } from '@ember/runloop';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';
import Core from '../../core';
import styles from './knob.module.css';

export default class InputRadioKnobKnob extends Core {
  baseClass = styles['knob-container'];
  propsToMap = ['angle', 'size'];
  styles = styles;

  @tracked _angle = 0;

  get activeOption() {
    return (this.normalizedAngle / this.shiftAngle) % this.args.optionCount;
  }

  get angle() {
    return this._angle;
  }

  set angle(change) {
    this._angle += change;
  }

  get normalizedAngle() {
    return ((this.angle % 360) + 360) % 360;
  }

  get shiftAngle() {
    return this.args.angle;
  }

  get size() {
    return this.args.size * .60;
  }

  calculateShortestPath = targetNormalized => {
    let diff = targetNormalized - this.normalizedAngle;

    if (diff > 180) return diff - 360;
    if (diff < -180) return diff + 360;

    return diff;
  }

  updateAngleFromOutside = modifier(() => {
    let { activeOption } = this.args;

    if ([undefined, null, this.activeOption].includes(activeOption)) return;

    next(this, () => {
      // Apply the shortest distance to the normalized angle
      this.angle = this.calculateShortestPath(this.shiftAngle * activeOption);
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
    <div
      class={{this.classes}}
      style={{this.props}}
      {{this.updateAngleFromOutside}}
    >
      <button
        class={{this.styles.knob}}
        style={{this.props}}
        type="button"
        {{on "click" this.click}}
        {{on "contextmenu" (fn this.click -1)}}
      />
    </div>
  </template>
};
