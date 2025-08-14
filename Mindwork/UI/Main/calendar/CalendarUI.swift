
import SwiftUI

struct CalendarUI: View {
    @StateObject private var viewModel = CalendarViewModel()
    
    var body: some View {
        Text("Stats Page")
    }
}
#Preview {
    CalendarUI()
}
