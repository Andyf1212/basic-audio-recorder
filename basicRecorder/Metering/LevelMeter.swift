

import SwiftUI

struct LevelMeter: View {
    
    var level: CGFloat
    
    // set my colors
    var gOff = Color(red: 34/255, green: 99/255, blue: 2/255)
    var gOn = Color(red: 85/255, green: 255/255, blue: 0/255)
    var yOff = Color(red: 135/255, green: 124/255, blue: 1/255)
    var yOn = Color(red: 255/255, green: 234/255, blue: 0/255)
    var rOff = Color(red: 89/255, green: 6/255, blue: 0/255)
    var rOn = Color(red: 250/255, green: 24/255, blue: 7/255)
    
    var numList = 1...100
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray)
            Rectangle()
                .fill(gOn)
                .frame(width: level, height: 30)
        }
    }
    
}


struct LevelMeter_Previews: PreviewProvider {
    static var previews: some View {
        LevelMeter(level: 10)
    }
}
