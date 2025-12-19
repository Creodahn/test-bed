import { camelize } from '@ember/string';
import { htmlSafe } from '@ember/template';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';
import Component from '@glimmer/component';

export default class Core extends Component {
  classesToMap = [];
  elementsToRegister = [];
  propsToMap = [];

  @tracked baseElement;

  get classes() {
    return [this.baseClass, ...this.mappedClasses.map(( { css }) => css)].join(' ');
  }

  get mappedClasses() {
    return this.classesToMap.map(css => {
      let camelized = camelize(css)
      let value = this[camelized] ?? this.args[camelized];

      return { css: this.styles[css], value };
    }).filter(({ value }) => value);
  }

  get props() {
    return htmlSafe(Object.entries(this.#mapProps()).map(([key, value]) => {
      return `--${key}: ${value};`;
    }).join(' '));
  }

  #mapProps = () => {
    return this.propsToMap.reduce((acc, prop) => {
      let camelized = camelize(prop)
      let value = this[camelized] ?? this.args[camelized];

      if (value !== undefined) {
        acc[prop] = value;
      }

      return acc;
    }, {});
  }

  #registerElements = element => {
    this.baseElement = element;

    for (let { name, selector } of this.elementsToRegister) {
      let isClass = selector[0] === '.';
      let parsedSelector = (isClass ? selector.slice(1) : selector).trim().toLowerCase();
      let query = isClass ? `.${this.styles[parsedSelector]}` : parsedSelector;
      let attrName = name ?? camelize(parsedSelector).replace(/[^a-z]/g, '');

      this[attrName] = this.baseElement.querySelector(query);
    }
  }

  setupComponent = modifier(element => {
    this.#registerElements(element);
    this.setup?.();
  });
}
