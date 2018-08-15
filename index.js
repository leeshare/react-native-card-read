import {
	Platform,
	NativeModules,
	NativeAppEventEmitter
} from 'react-native';

//module.exports = NativeModules.CardModule;

let CardModule = NativeModules.CardModule;

export default {
	init(options){
		let opt = {
		    onReturn(){},
			...options
		};
		let fnConf = {
			confirm: opt.onReturn,
		};
		CardModule.init(opt);
		this.listener && this.listener.remove();
    this.listener = NativeAppEventEmitter.addListener('confirmEvent', event => {
      fnConf[event['type']](event['peripherResult'], event['peripherType']);
    });
	},
	show_peripher_list(options){
		CardModule.show_peripher_list(options);
	},
	connect_peripher(options){
		CardModule.connect_peripher(options);
	},
	read_card_info(options){
		CardModule.read_card_info(options);
	}
}
