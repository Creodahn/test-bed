import { pageTitle } from 'ember-page-title';
import RadioKnob from 'test-bed/components/input/radio-knob';

<template>
  {{pageTitle "Testbed"}}

  <RadioKnob @size={{250}} as |RK|>
    <RK.knob />
    <RK.option checked="true">Option 1</RK.option>
    <RK.option>Option 2</RK.option>
    <RK.option>Option 3</RK.option>
    <RK.option>Option 4</RK.option>
    <RK.option>Option 5</RK.option>
    <RK.option>Option 6</RK.option>
  </RadioKnob>
</template>
