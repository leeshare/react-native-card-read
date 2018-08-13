import {
	Platform,
	NativeModules,
	NativeAppEventEmitter
} from 'react-native';

//module.exports = NativeModules.CardModule;

let CardModule = NativeModules.CardModule;

export default {
	init_peripher_list(options){
		let opt = {
		    onReturn(){},
			...options
		};
		let fnConf = {
			confirm: opt.onReturn,
		};
		CardModule.show_peripher_list(opt);
		this.listener && this.listener.remove();
    this.listener = NativeAppEventEmitter.addListener('confirmEvent', event => {
      fnConf[event['type']](event['peripherResult']);
    });
	},
	connect_peripher(options){
		CardModule.connect_peripher(options);
	}
}
