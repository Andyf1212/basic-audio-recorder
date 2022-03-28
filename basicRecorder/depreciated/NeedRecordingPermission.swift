

import SwiftUI

struct NeedRecordingPermission: View {
    var body: some View {
        Text("Microphone access not enabled.  Please allow access under Settings -> Privacy -> Microphone.")
    }
}

struct NeedRecordingPermission_Previews: PreviewProvider {
    static var previews: some View {
        NeedRecordingPermission()
    }
}
