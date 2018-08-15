package com.hc.card;

import android.content.Context;
import android.content.Intent;
import android.os.Handler;

import cn.com.senter.mediator.NFCardReader;

public class NFCReaderHelper {

	private Context context;

	private NFCardReader nfCardReader;

	public NFCReaderHelper(Context context, Handler handler) {
		this.context = context;
		nfCardReader = new NFCardReader(handler, context);
	}

	public void read() {
		nfCardReader.EnableSystemNFCMessage();
	}

	public void disable() {
		nfCardReader.DisableSystemNFCMessage();
	}

	public boolean isNFC(Intent intent) {

		return nfCardReader.isNFC(intent);

	}

	public String readCardWithIntent(Intent tag) {
		return nfCardReader.readCardWithIntent_Sync(tag);
	}

	public void setServerAddress(String server_address) {
		nfCardReader.setServerAddress(server_address);

	}

	public void setServerPort(int server_port) {
		nfCardReader.setServerPort(server_port);
	}
	
	public void OnDestroy(){
		nfCardReader.OnDestroy();
	}
}
