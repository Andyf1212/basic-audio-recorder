//
//
//import SwiftUI
//
//struct LevelMeter: View {
//    
//    var level: CGFloat = 50.0
//    
//    
//    
////    var barArray = buildBars()
////    var count: Int = 0
//    
//    var body: some View {
//        
//        ZStack {
//            Rectangle()
//                .fill(Color.gray)
//                .padding()
//            HStack { 
//                
//            }
//        }
//    }
//    
//    
//    
//}
//
//struct LevelBars: View {
//    var numBars: Int
//    var count: Int = 0
//    
//    var body: some View {
//        HStack {
//            LevelBar()
//        }
//    }
//}
//
//struct LevelBar: View {
//    var color: Color
//    var level: Double
//    var body: some View {
//        pickColor()
//        Rectangle()
//    }
//    
//    func pickColor() {
//        if level < 60 {
//            color = Color.green
//        } else if level < 90 {
//            color = Color.yellow
//        } else {
//            color = Color.red
//        }
//    }
//}
//
//
//struct LevelMeter_Previews: PreviewProvider {
//    static var previews: some View {
//        LevelMeter(level: 10)
//    }
//}
