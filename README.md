# ReorderingVStack

A simple SwiftUI view that lets you reorder items in a vertical stack with drag-and-drop.

## Preview
<p align=center>
<img src=https://github.com/user-attachments/assets/578c3393-f231-4fba-915f-01a5e6535368 width=100%>
</p>

## Usage
``` swift
import SwiftUI
import ReorderingVStack // import the package

struct ContentView: View {
    @State private var items = Item.mocks // must conform to Hashable and Identifiable

    var body: some View {
        ReorderingVStack(items: $items, spacing: 10) { item in
            HStack {
                Text(item.title)
                Spacer()
                Image(systemName: "line.3.horizontal")
                    .dragToReorder() // makes the image act as the drag handle
            }
            .padding()
            .background(.background.secondary, in: .rect(cornerRadius: 8))
        }
        .padding()
    }
}
```

## Installation

Add it to your project with Swift Package Manager by using the repository URL.


## License

ReorderingVStack is open source and available under the MIT License. See the LICENSE file for more details.
