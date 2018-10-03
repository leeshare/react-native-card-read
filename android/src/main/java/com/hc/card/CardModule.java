
package com.hc.card;

import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.app.Dialog;
import android.app.PendingIntent;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.hardware.Camera;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.net.Uri;
import android.nfc.NfcAdapter;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.os.PowerManager;
import android.os.SystemClock;
import android.support.annotation.Nullable;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.support.v4.content.PermissionChecker;
import android.text.TextUtils;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ArrayAdapter;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import cn.com.senter.helper.ShareReferenceSaver;
import cn.com.senter.sdkdefault.helper.Error;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Set;
import java.util.concurrent.Executors;

import static android.Manifest.permission.RECORD_AUDIO;
import static android.graphics.Color.argb;

import android.widget.Toast;

import org.apache.commons.lang3.StringUtils;
import org.codehaus.jackson.JsonFactory;
import org.codehaus.jackson.JsonProcessingException;
import org.codehaus.jackson.map.ObjectMapper;

import cn.com.senter.helper.ConsantHelper;
import cn.com.senter.model.IdentityCardZ;

/**
 * Author: wj
 * <p>
 * Created by wj on 18/8/10.
 * <p>
 * connect by peripher to read certificate card
 * <p>
 */

public class CardModule extends ReactContextBaseJavaModule{

    Activity activity;
    private Context mContext;

    private static final String CONFIRM_EVENT_NAME = "confirmEvent";
    private static final String EVENT_KEY_CONFIRM = "confirm";

    //-----
    private final static String SERVER_KEY1 = "CN.COM.SENTER.SERVER_KEY1";
	private final static String PORT_KEY1 = "CN.COM.SENTER.PORT_KEY1";
	private final static String BLUE_ADDRESSKEY = "CN.COM.SENTER.BLUEADDRESS";
	private final static String KEYNM = "CN.COM.SENTER.KEY";
	public static int READER_FLAGS = 131;

    long counttime = 0;
	long starttime = 0;
	long averagetime = 0;

	int testcount = 0;
	int successcount = 0;
	int failedcount = 0;

	private String server_address = "";
	private int server_port = 0;

	public static Handler uiHandler;

	private NFCReaderHelper mNFCReaderHelper;
	private OTGReaderHelper mOTGReaderHelper;
	private BlueReaderHelper mBlueReaderHelper;

    private AsyncTask<Void, Void, String> nfcTask = null;

    //----蓝牙功能有关的变量----
    private BluetoothAdapter mBluetoothAdapter = null;			///蓝牙适配器

    private int iselectNowtype = 1;
    private String Blueaddress = null;
    private boolean bSelServer = false;

    private int totalcount;
    private int failecount;

    private boolean isbule;
    private boolean isNFC;
    private boolean openblueok;
    private PowerManager.WakeLock wakeLock = null;
    String et_mmsnumber = "";
    String et_imsinumber = "";
    private boolean bIsAuto;

	private PendingIntent pendingIntent;
	private NfcAdapter nfcAdapter;

	//------------------------


    public CardModule(ReactApplicationContext reactContext){
        super(reactContext);
    }

    @Override
    public String getName() {
        return "CardModule";
    }

    @ReactMethod
	public void init(ReadableMap options){
    	activity = getCurrentActivity();
        Intent intent = activity.getIntent();

		uiHandler = new MyHandler(activity);

		// Get the local Bluetooth adapter
        mBtAdapter = BluetoothAdapter.getDefaultAdapter();

        mBlueReaderHelper = new BlueReaderHelper(activity, uiHandler);

		Blueaddress = ShareReferenceSaver.getData(activity, BLUE_ADDRESSKEY);
        initShareReference();

		mPairedDevicesArrayAdapter = new ArrayAdapter<String>(activity, 0);
		mNewDevicesArrayAdapter = new ArrayAdapter<String>(activity, 0);

		//注册广播
		// Register for broadcasts when a device is discovered
		IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
		activity.registerReceiver(mReceiver, filter);

		// Register for broadcasts when discovery has finished
		filter = new IntentFilter(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
		activity.registerReceiver(mReceiver, filter);

		//mBtAdapter = BluetoothAdapter.getDefaultAdapter();

		// Get a set of currently paired devices
		Set<BluetoothDevice> pairedDevices = mBtAdapter.getBondedDevices();

		// If there are paired devices, add each one to the ArrayAdapter
        if (pairedDevices.size() > 0) {
            for (BluetoothDevice device : pairedDevices) {
                //mPairedDevicesArrayAdapter.add(device.getName() + "\n" + device.getAddress());
				mPairedDevicesArrayAdapter.add(device.getName() + "H-C" + device.getAddress());
            }
        } else {
            //String noDevices = getResources().getText(R.string.none_paired).toString();
			String noDevices = "没有任何设备";
            mPairedDevicesArrayAdapter.add(noDevices);
        }


	}


    //1 获取并返回一个设备列表
    @ReactMethod
    public void show_peripher_list(ReadableMap options){

        //重新搜索
        if (mBtAdapter.isDiscovering()) {
            mBtAdapter.cancelDiscovery();
        }

        // Request discover from BluetoothAdapter
        mBtAdapter.startDiscovery();

        //commonEvent(EVENT_KEY_CONFIRM, 1);
    }

    //2 点击某一个设备进行 蓝牙连接
    @ReactMethod
    public void connect_peripher(ReadableMap options){
		mBtAdapter.cancelDiscovery();
		if(options != null && options.hasKey("mac")){
			Blueaddress = options.getString("mac");
			String name = options.getString("name");
			if (!Blueaddress.matches("([0-9a-fA-F][0-9a-fA-F]:){5}([0-9a-fA-F][0-9a-fA-F])"))
			{
				//tv_info.setText("address:" + Blueaddress + " is wrong, length = " + Blueaddress.length());
				alert("name:" + name + "[address:" + Blueaddress + "] is wrong, length = " + Blueaddress.length());
			    return;
			}
			ShareReferenceSaver.saveData(activity, BLUE_ADDRESSKEY, Blueaddress);

			commonEvent(EVENT_KEY_CONFIRM, 2);
		}

    }

    //3 蓝牙读卡
    @ReactMethod
    public void read_card_info(ReadableMap options){

    	isbule = true;
		iselectNowtype = 3;
		readCardBlueTooth();

        //commonEvent(EVENT_KEY_CONFIRM, 3);
    }



    private void commonEvent(String eventKey, Integer type) {
        WritableMap map = Arguments.createMap();
        map.putString("type", eventKey);
        /*WritableArray indexes = Arguments.createArray();
        WritableArray values = Arguments.createArray();
        for (ReturnData data : returnData) {
            indexes.pushInt(data.getIndex());
            values.pushString(data.getItem());
        }*/

        String peripherResult = "";

        if(type == 1){
            for(int i = 0; i < mNewDevicesArrayAdapter.getCount(); i++){
            	String str = mNewDevicesArrayAdapter.getItem(i);
            	peripherResult += str + "H,C";
			}
			peripherResult += "H||C";
			for(int i = 0; i < mPairedDevicesArrayAdapter.getCount(); i++){
            	String str = mPairedDevicesArrayAdapter.getItem(i);
            	peripherResult += str + "H,C";
			}
		} else if(type == 2){
        	alert("已选中");
		} else if(type == 3){
        	peripherResult = strCardInfo;
		}

		if(type == -3){
        	peripherResult = readErrorMessage;
		}

        map.putString("peripherResult", peripherResult);
        map.putString("peripherType", type.toString());
        sendEvent(getReactApplicationContext(), CONFIRM_EVENT_NAME, map);

        readErrorMessage = "";
        readErrorCode = 0;
        strCardInfo = "";
    }

    private void sendEvent(ReactContext reactContext,
                           String eventName,
                           @Nullable WritableMap params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    //--------------------------------------------------

    @ReactMethod
    public void alert(String message) {
        Toast.makeText(getReactApplicationContext(), message, Toast.LENGTH_LONG).show();
    }

    @ReactMethod
    public void checkPermissionCamera(Callback callback){
        boolean canUse = true;
        Camera mCamera = null;
        try{
            mCamera = Camera.open();
            Camera.Parameters mParameters = mCamera.getParameters();
            mCamera.setParameters(mParameters);
        }catch(Exception e) {
            canUse = false;
        }
        if(mCamera != null) {
            mCamera.release();
        }
        WritableMap result = new WritableNativeMap();
        result.putBoolean("is_success", canUse);
        callback.invoke(result);
    }

    @ReactMethod
    public void openSettings(){
        activity = getCurrentActivity();
        if(activity != null) {
            mContext = activity.getApplicationContext();
            Intent intent = new Intent();

            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                if(Build.VERSION.SDK_INT>=9){
                    intent.setAction("android.settings.APPLICATION_DETAILS_SETTINGS");
                    intent.setData(Uri.fromParts("package", mContext.getPackageName(),null));
                }else if(Build.VERSION.SDK_INT<=8){
                    intent.setAction(Intent.ACTION_VIEW);
                    intent.setClassName("com.android.settings","com.android.setting.InstalledAppDetails");
                    intent.putExtra("com.android.settings.ApplicationPkgName", mContext.getPackageName());
                }
                mContext.startActivity(intent);
            } catch(Exception e){
                e.printStackTrace();
            }
        }
    }

    //--------------------------------------------

	private void initShareReference() {

		if ( this.server_address.length() <= 0){
			if (ShareReferenceSaver.getData(activity, SERVER_KEY1).trim().length() <= 0) {
				 this.server_address = "senter-online.cn";//
			} else {
				this.server_address = ShareReferenceSaver.getData(activity, SERVER_KEY1);
			}
			if (ShareReferenceSaver.getData(activity, PORT_KEY1).trim().length() <= 0) {
				this.server_port = 10002;
			} else {
				this.server_port = Integer.valueOf(ShareReferenceSaver.getData(activity, PORT_KEY1));
			}
		}

		//mNFCReaderHelper.setServerAddress(this.server_address);
		//mNFCReaderHelper.setServerPort(this.server_port);

		//mOTGReaderHelper.setServerAddress(this.server_address);
		//mOTGReaderHelper.setServerPort(this.server_port);

		//----实例化help类---
		mBlueReaderHelper.setServerAddress(this.server_address);
		mBlueReaderHelper.setServerPort(this.server_port);

	}

	/**
	 * 蓝牙读卡方式
	 */
	private class BlueReadTask extends AsyncTask<Void, Void, String> {

		@Override
		protected void onPostExecute(String strCardInfo) {


			if (TextUtils.isEmpty(strCardInfo)) {
				uiHandler.sendEmptyMessage(ConsantHelper.READ_CARD_FAILED);
				//ButtondefDrawable();
				nfcTask = null;
				failecount++;
				return;
			}

			if (strCardInfo.length() <=2){
				readCardFailed(strCardInfo);
				//ButtondefDrawable();
				nfcTask = null;
				failecount++;
				return;
			}

			ObjectMapper objectMapper = new ObjectMapper();
			IdentityCardZ mIdentityCardZ = new IdentityCardZ();

			try {
				mIdentityCardZ = (IdentityCardZ) objectMapper.readValue(
						strCardInfo, IdentityCardZ.class);
			} catch (Exception e) {
				e.printStackTrace();
				nfcTask = null;

				return;
			}
			totalcount++;
			readCardSuccess(mIdentityCardZ);

			 try {

			 Bitmap bm = BitmapFactory.decodeByteArray(mIdentityCardZ.avatar,
			 0, mIdentityCardZ.avatar.length);
			 DisplayMetrics dm = new DisplayMetrics();
			 //getWindowManager().getDefaultDisplay().getMetrics(dm);
			 activity.getWindowManager().getDefaultDisplay().getMetrics(dm);

			 //photoView.setMinimumHeight(dm.heightPixels);
			 //photoView.setMinimumWidth(dm.widthPixels);
			 //photoView.setImageBitmap(bm);
			 } catch (Exception e) {
			 }

			//ButtondefDrawable();
			nfcTask = null;

			super.onPostExecute(strCardInfo);

		}

		@Override
		protected String doInBackground(Void... params) {

			String strCardInfo =mBlueReaderHelper.read();
			return strCardInfo;
		}
	};

	/**
	 * 蓝牙读卡方式
	 */
	protected void readCardBlueTooth()
	{
		if (isNFC){
			mNFCReaderHelper.disable();
			isNFC = false;
		}

		if ( Blueaddress == null){
			//Toast.makeText(this, "请选择蓝牙设备，再读卡!", Toast.LENGTH_LONG).show();
			Toast.makeText(activity, "请选择蓝牙设备，再读卡!", Toast.LENGTH_LONG).show();
			return;
		}

		if ( Blueaddress.length() <= 0){
			//Toast.makeText(this, "请选择蓝牙设备，再读卡!", Toast.LENGTH_LONG).show();
			Toast.makeText(activity, "请选择蓝牙设备，再读卡!", Toast.LENGTH_LONG).show();
			return;
		}
		if (mBlueReaderHelper.registerBlueCard(Blueaddress) == true){

			new BlueReadTask()
			.executeOnExecutor(Executors.newCachedThreadPool());
		}else{
			//Toast.makeText(this, "请确认蓝牙设备已经连接，再读卡!", Toast.LENGTH_LONG).show();
			Toast.makeText(activity, "请确认蓝牙设备已经连接，再读卡!", Toast.LENGTH_LONG).show();
		}
	}

	private String strCardInfo = "";
	private int readErrorCode = 0;
	private String readErrorMessage = "";

	private void readCardFailed(String strcardinfo){
		int bret = Integer.parseInt(strcardinfo);
		switch (bret){
		case -1:
			//tv_info.setText("服务器连接失败!");
			readErrorMessage = "服务器连接失败!";
			break;
		case 1:
			//tv_info.setText("读卡失败!");
			readErrorMessage = "读卡失败!";
			break;
		case 2:
			//tv_info.setText("读卡失败!");
			readErrorMessage = "读卡失败!";
			break;
		case 3:
			//tv_info.setText("网络超时!");
			readErrorMessage = "网络超时!";
			break;
		case 4:
			//tv_info.setText("读卡失败!");
			readErrorMessage = "读卡失败!";
			break;
		case -2:
			//tv_info.setText("读卡失败!");
			readErrorMessage = "读卡失败!";
			break;
		case 5:
			//tv_info.setText("照片解码失败!");
			readErrorMessage = "照片解码失败!";
			break;
		}
		readErrorCode = bret;

		commonEvent(EVENT_KEY_CONFIRM, -3);
	}

	public static String toJSON(Object obj) {
		ObjectMapper om = new ObjectMapper();
		try {
			String json = om.writeValueAsString(obj);
			return json;
		} catch (JsonProcessingException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}


	private void readCardSuccess(IdentityCardZ identityCard) {

		if (identityCard != null) {

			if (identityCard.type != null){
				//外籍身份证
                //identityCard.enname


				/*nameTextView.setText(identityCard.name);
				tv_enname.setText(identityCard.enname);
				Labelehtnic.setText("");
				Lableaddress.setText("国籍");
				folkTextView.setText("");
				addrTextView.setText(identityCard.ethnicity);*/
			}else{
				//本国身份证
				//identityCard.name

				/*Labelehtnic.setText("民族");
				Lableaddress.setText("住址");
				nameTextView.setText(identityCard.name);
				folkTextView.setText(identityCard.ethnicity);
				addrTextView.setText(identityCard.address);*/
			}

			/*identityCard.sex
			birthTextView.setText(identityCard.birth);
			codeTextView.setText(identityCard.cardNo);
			policyTextView.setText(identityCard.authority);
			validDateTextView.setText(identityCard.period);*/
		}

		//dnTextView.setText("成功:" + String.format("%d", totalcount) + " 失败:" + String.format("%d", failecount));
		//tv_info.setText("读取成功!");

		SystemClock.sleep(200);
		if (bIsAuto == true){
			switch(iselectNowtype){
			case 2:
				//readCardOTG();
				break;
			case 3:
				readCardBlueTooth();

				break;
			}
		}

		strCardInfo = toJSON(identityCard);

		commonEvent(EVENT_KEY_CONFIRM, 3);

	}

	//-----------
	class MyHandler extends Handler {
		private Activity activity;

		MyHandler(Activity activity) {
			this.activity = activity;
		}

		@Override
		public void handleMessage(Message msg) {

			switch (msg.what) {
			case ConsantHelper.READ_CARD_SUCCESS:
			    alert("READ_CARD_SUCCESS");

				break;

			case ConsantHelper.SERVER_CANNOT_CONNECT:
				alert("服务器连接失败! 请检查网络。");
				break;

			case ConsantHelper.READ_CARD_FAILED:
				alert("无法读取信息请重试!");
				break;

			case ConsantHelper.READ_CARD_WARNING:
				alert("请移动卡片在合适位置!");
				break;

			case ConsantHelper.READ_CARD_PROGRESS:

                int progress_value = (Integer) msg.obj;

				//alert("正在读卡......进度" + progress_value );//,进度：+ progress_value + "%"
				break;

			case ConsantHelper.READ_CARD_START:
				alert("正在读卡......");
				break;
			case Error.ERR_CONNECT_SUCCESS:
				String devname = (String) msg.obj;
				//alert(devname+"连接成功!" );
				break;
			case Error.ERR_CONNECT_FAILD:
				String devname1 = (String) msg.obj;
				//alert(devname1+"连接失败!" );
				break;
			case Error.ERR_CLOSE_SUCCESS:
				//alert((String) msg.obj+"断开连接成功");
				break;
			case Error.ERR_CLOSE_FAILD:
				//alert((String) msg.obj+"断开连接失败");
				break;
			case Error.RC_SUCCESS:
				String devname12 = (String) msg.obj;
				//alert(devname12+"连接成功!");
				break;

			}
		}

	}
	//------------------ 蓝牙列表
	// Member fields
    private BluetoothAdapter mBtAdapter;

	private ArrayAdapter<String> mPairedDevicesArrayAdapter;
	private ArrayAdapter<String> mNewDevicesArrayAdapter;

	private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();

            // When discovery finds a device
            if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                // Get the BluetoothDevice object from the Intent
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                // If it's already paired, skip it, because it's been listed already
                if (device.getBondState() != BluetoothDevice.BOND_BONDED) {
                    //mNewDevicesArrayAdapter.add(device.getName() + "\n" + device.getAddress());
					mNewDevicesArrayAdapter.add(device.getName() + "H-C" + device.getAddress());
                }
            // When discovery is finished, change the Activity title
            } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                //setProgressBarIndeterminateVisibility(false);
                //setTitle(R.string.select_device);
                if (mNewDevicesArrayAdapter.getCount() == 0) {
                    //String noDevices = getResources().getText(R.string.none_found).toString();
					String noDevices = "没有任何设备";
                    mNewDevicesArrayAdapter.add(noDevices);
                }
            }


			commonEvent(EVENT_KEY_CONFIRM, 1);
        }
    };

	//--------------------------

}
