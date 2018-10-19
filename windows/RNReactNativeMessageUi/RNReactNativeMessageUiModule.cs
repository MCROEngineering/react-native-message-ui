using ReactNative.Bridge;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Core;
using Windows.UI.Core;

namespace React.Native.Message.Ui.RNReactNativeMessageUi
{
    /// <summary>
    /// A module that allows JS to share data.
    /// </summary>
    class RNReactNativeMessageUiModule : NativeModuleBase
    {
        /// <summary>
        /// Instantiates the <see cref="RNReactNativeMessageUiModule"/>.
        /// </summary>
        internal RNReactNativeMessageUiModule()
        {

        }

        /// <summary>
        /// The name of the native module.
        /// </summary>
        public override string Name
        {
            get
            {
                return "RNReactNativeMessageUi";
            }
        }
    }
}
