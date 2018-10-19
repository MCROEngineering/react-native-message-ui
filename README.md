
# react-native-react-native-message-ui

## Getting started

`$ npm install react-native-react-native-message-ui --save`

### Mostly automatic installation

`$ react-native link react-native-react-native-message-ui`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-react-native-message-ui` and add `RNReactNativeMessageUi.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNReactNativeMessageUi.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNReactNativeMessageUiPackage;` to the imports at the top of the file
  - Add `new RNReactNativeMessageUiPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-react-native-message-ui'
  	project(':react-native-react-native-message-ui').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-react-native-message-ui/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-react-native-message-ui')
  	```

## Usage
```javascript
import RNReactNativeMessageUi from 'react-native-react-native-message-ui';

RNReactNativeMessageUi.showMessageComposeWithOptions(
    {
        body : 'Some message here ..',
        recipients : ['11211241', 'b@bb.bbb'],
        disableUserAttachments : true
    }, (error, messageComposeResult) => {
        if (error) {
            console.error(error);
        } else {
            Alert.alert('mailComposeResult : ' + messageComposeResult);
        }
    }
);
```
