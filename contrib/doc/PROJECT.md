Overview of the Application
The application is a cross-platform iOS/macOS app for interacting with smart 3x3x3 Rubik's cubes via Bluetooth. The core feature is a virtual 3D cube rendered in SceneKit that syncs in real-time with physical smart cubes and it's turns. The app must be agnostic to specific cube models, meaning it should support multiple smart cube brands/protocols through modular design, starting with the Qiyi Tornado v4 AI cube. Physical turns on the cube update the virtual model's state, and the virtual cube should scale dynamically to the window/view size.
Key goals:

Discover and connect to nearby smart cubes via Bluetooth Low Energy (BLE).
Parse cube state changes (turns, orientations) from BLE data.
Render a responsive 3D cube using SceneKit.
Ensure modularity for future cube model support (e.g., via protocol adapters).

Architecture and Tech Stack

Platform: iOS and macOS (using SwiftUI for UI, shared code via Swift for cross-platform compatibility).
Bluetooth: Core Bluetooth framework for scanning, connecting, and handling BLE peripherals.
3D Rendering: SceneKit for the virtual cube.
State Management: Use a central CubeState model (e.g., a 3D array or enum-based representation) to track the cube's configuration. Sync this with BLE updates.
Modularity: Define a protocol like SmartCubeProtocol for handling model-specific BLE services/characteristics. Implement a concrete class for Tornado v4 AI, with hooks for others.
Use resizable view, virtual cube in the center.
If connection is not establish rotation can be done with keyboard buttons according the speedcubing notation. Move with pressed Shift do the opposite move, for example B becames B'.
UI: Put buttons mostly to the corners.
Use popup, blured, partially transparent popup windows in tech mode.
We need popup for cubes discovery
We need popup for debug infromation (all components must print debug info, use will know and good SwiftUI library for the debuging)

Bluetooth Integration

Discovery and Connection:
Use CBCentralManager to scan for peripherals with services matching known smart cube UUIDs or name.

For model-agnostic detection: Scan without specific service filters initially, then query discovered peripherals for known characteristics to identify the model (e.g., check for Tornado v4's service UUID).

Handle multiple cubes: Maintain a list of discovered devices, allow user selection, and connect to one or more (if multi-cube support is desired).

Permissions: Request Bluetooth permissions in Info.plist and handle states (powered on, unauthorized, etc.).

Protocol Handling:
We will discovery specific protocols on the next stage

Model Agnosticism:
Create an abstraction layer: SmartCubeAdapter protocol with all required generic methods, so that we can use it for different types of cubes and protocols.


Development Steps

1. Create a 3d cube visualization

2. Design abstract protocols and interfaces

3. Mybe we can use this intefaces to implement adapter for the Keyboard bindings

4. Anyway we must be able to rotate 3d model with mouse and make turns with the keyboard  L, R, B, F and all of them according notaiton.

5. We will start working on the Tornado V4 protocol and it's adapter.