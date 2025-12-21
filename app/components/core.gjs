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

  #processWithHandler = (selector, handler, name) => {
    const parsed = selector.slice(1).trim();
    return {
      query: handler(parsed),
      attrName: name ?? camelize(parsed).replace(/[^a-zA-Z]/g, ''),
    };
  };

  #processTagSelector = (selector, name) => {
    const query = selector.trim().toLowerCase();
    return {
      query,
      attrName: name ?? camelize(query).replace(/[^a-zA-Z]/g, ''),
    };
  };

  #registerElements = element => {
    this.baseElement = element;

    const selectorHandlers = {
      '.': (sel) => `.${this.styles[sel.toLowerCase()]}`,
      '#': (sel) => `#${sel}`,
    };

    for (let { name, selector } of this.elementsToRegister) {
      const firstChar = selector[0];
      const handler = selectorHandlers[firstChar];
      const { query, attrName } = handler
        ? this.#processWithHandler(selector, handler, name)
        : this.#processTagSelector(selector, name);

      this[attrName] = this.baseElement.querySelector(query);
    }
  };

  setupComponent = modifier(element => {
    this.#registerElements(element);
    this.setup?.();
  });
}
