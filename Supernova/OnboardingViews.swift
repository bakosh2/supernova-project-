import SwiftUI
import UIKit
import ImageIO

/// حاوية تضبط حجم صورة الـ GIF وفق إطار SwiftUI بدقة.
/// استخدام UIImageView مباشرة يجعل بعض ملفات GIF تعود لحجمها الأصلي الكبير.
final class GIFImageContainer: UIView {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // نعيد تعيين الإطار هنا لضمان بقاء الصورة كاملة داخل المساحة المطلوبة.
        imageView.frame = bounds
    }
}

/// يعرض ملف GIF من الـ Assets كرسوم متحركة داخل SwiftUI.
struct AnimatedGIFImage: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> GIFImageContainer {
        let container = GIFImageContainer()
        container.backgroundColor = .clear
        container.imageView.image = animatedImage(named: resourceName)
        return container
    }

    func updateUIView(_ container: GIFImageContainer, context: Context) {}

    private func animatedImage(named name: String) -> UIImage? {
        guard let asset = NSDataAsset(name: name),
              let source = CGImageSourceCreateWithData(asset.data as CFData, nil) else { return nil }

        let frameCount = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var totalDuration: Double = 0

        for index in 0..<frameCount {
            guard let image = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                ?? (gif?[kCGImagePropertyGIFDelayTime] as? Double)
                ?? 0.1
            totalDuration += delay
            frames.append(UIImage(cgImage: image))
        }
        return UIImage.animatedImage(with: frames, duration: totalDuration)
    }
}

// MARK: - 2. شكل انحناء سطح الكوكب (مصحح لتطابق بروتوكول Shape)
struct PlanetSurfaceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: h * 0.35))
        
        path.addQuadCurve(
            to: CGPoint(x: w, y: h * 0.35),
            control: CGPoint(x: w / 2, y: -20)
        )
        
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - 3. أرضية سطح الكوكب مع التوهج الفضائي
struct PlanetSurfaceView: View {
    var body: some View {
        ZStack(alignment: .top) {
            PlanetSurfaceShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color("tiffany").opacity(0.8),
                            Color.purple.opacity(0.6),
                            Color("tiffany").opacity(0.2)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 3
                )
                .blur(radius: 4)
                .offset(y: -2)
            
            PlanetSurfaceShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.10, blue: 0.30),
                            Color(red: 0.10, green: 0.06, blue: 0.20),
                            Color(red: 0.05, green: 0.03, blue: 0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Circle()
                        .fill(Color("tiffany").opacity(0.12))
                        .frame(width: 300, height: 100)
                        .blur(radius: 30)
                        .offset(y: -20)
                )
        }
        .frame(height: 180)
    }
}

// MARK: - 4. Intro Screen (WelcomeView)

struct WelcomeView: View {
    @State private var cardScale: CGFloat = 0.85
    @State private var cardOpacity: Double = 0.0
    @State private var textGlow: Double = 0.3
    @State private var navigateToModeSelection: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackgroundView()
                
                VStack {
                    Spacer()
                    PlanetSurfaceView()
                }
                .ignoresSafeArea(edges: .bottom)
                
                VStack {
                    Spacer()
                    
                    VStack(spacing: 28) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color("tiffany").opacity(0.3), Color.purple.opacity(0.1), .clear],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .blur(radius: 15)
                            
                            Image("astronaut 2")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 220, maxHeight: 190)
                                .shadow(color: Color("tiffany").opacity(0.5), radius: 15)
                        }
                        
                        VStack(spacing: 8) {
                            Text("SUPERNOVA")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .tracking(4)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color("tiffany"), Color.purple.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color("tiffany").opacity(textGlow), radius: 15)
                            
                            Text("رحلتك التفاعلية نحو الفضاء والتعلم")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                navigateToModeSelection = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                Text("ابدأ الرحلة")
                                    .font(.system(size: 20, weight: .bold))
                            
                            }
                            .foregroundColor(.white)
                            .frame(width: 220, height: 56)
                            .supernovaGlassCapsule()
                        }
                        .padding(.top, 5)
                    }
                    .padding(.vertical, 36)
                    .padding(.horizontal, 28)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 32)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.22, green: 0.14, blue: 0.38).opacity(0.85),
                                            Color(red: 0.12, green: 0.08, blue: 0.25).opacity(0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Circle()
                                .fill(Color("tiffany").opacity(0.15))
                                .frame(width: 160, height: 160)
                                .blur(radius: 35)
                                .offset(x: -100, y: -70)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color("tiffany").opacity(0.6),
                                        Color.purple.opacity(0.4),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 25, x: 0, y: 12)
                    .shadow(color: Color("tiffany").opacity(0.2), radius: 15, x: 0, y: 0)
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .frame(maxWidth: 460)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding(.bottom, 60)
            }
            .navigationDestination(isPresented: $navigateToModeSelection) {
                ContentView()
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    cardScale = 1.0
                    cardOpacity = 1.0
                }
                
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    textGlow = 0.8
                }
            }
        }
    }
}

// MARK: - 5. الشاشة الثانية: اختيار الوضع (ContentView)
struct ContentView: View {
    @State private var showParentPinFlow = false
    @State private var showChildDashboard = false
    @AppStorage("childProfileName") private var childProfileName = ""

    private var childButtonTitle: String {
        let name = childProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "الطفل" : name
    }
    
    var body: some View {
        ZStack {
            SpaceBackgroundView()
            
            VStack(spacing: 40) {
                VStack(spacing: 15) {
                    Text("مرحبًا !")
                        .font(.system(size: 55, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("من يستخدم التطبيق حاليًا؟")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 220/255, green: 180/255, blue: 255/255),
                                    Color.white
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }
                
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 50) {
                        Button(action: {
                            showChildDashboard = true
                        }) {
                            Text(childButtonTitle)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 270, height: 90)
                                .supernovaGlassCapsule()
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            showParentPinFlow = true
                        }) {
                            Text("الوالدين")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 270, height: 90)
                                .supernovaGlassCapsule()
                                .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // الشخصية المتحركة التي أُضيفت إلى Assets.xcassets.
                    AnimatedGIFImage(resourceName: "child gif")
                        // تظهر الشخصية كاملة وكأنها جالسة على حافة زر الطفل.
                        .frame(width: 165, height: 165)
                        .offset(x: -30, y: -115)
                        .allowsHitTesting(false)
                }
                .padding(.top, 130)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showParentPinFlow) {
            ParentPinFlowView()
        }
        .navigationDestination(isPresented: $showChildDashboard) {
            TodaysMissionsView()
        }
    }
}

// MARK: - 6. الشاشة الثالثة: أدخل رمز PIN (ParentPinFlowView)
struct ParentPinFlowView: View {
    @AppStorage("savedParentPin") private var savedPin: String = ""
    @AppStorage("hasCompletedChildSetup") private var hasCompletedChildSetup = false
    
    @State private var enteredPin: String = ""
    @State private var tempFirstPin: String = ""
    @State private var step: PinStep = .create
    @State private var errorMessage: String = ""
    @State private var navigateToChildProfile = false
    
    @Environment(\.dismiss) var dismiss
    
    enum PinStep {
        case create, confirm, enter
    }
    
    var body: some View {
        ZStack {
            SpaceBackgroundView()
            
            VStack {
                HStack {
                    BackCapsuleButton(action: handleBackButton)
                    Spacer()
                }
                .padding(.top, AppHeaderLayout.top)
                .padding(.leading, AppHeaderLayout.horizontal)
                Spacer()
            }
            .zIndex(10)
            
            VStack(spacing: 25) {
                Spacer()
                
                VStack(spacing: 10) {
                    Text(headerTitle)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(headerSubtitle)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.85))
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.red.opacity(0.9))
                            .padding(.top, 4)
                    }
                }
                
                HStack(spacing: 18) {
                    ForEach(0..<4, id: \.self) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .frame(width: 65, height: 65)
                                .shadow(color: Color("tiffany").opacity(index < enteredPin.count ? 0.6 : 0.0), radius: 10)
                            
                            if index < enteredPin.count {
                                Circle()
                                    .fill(Color(red: 0.12, green: 0.38, blue: 0.35))
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                
                VStack(spacing: 14) {
                    let rows = [
                        ["1", "2", "3"],
                        ["4", "5", "6"],
                        ["7", "8", "9"]
                    ]
                    
                    ForEach(rows, id: \.self) { row in
                        HStack(spacing: 22) {
                            ForEach(row, id: \.self) { num in
                                KeypadButton(text: num) {
                                    appendDigit(num)
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 22) {
                        Color.clear.frame(width: 70, height: 70)
                        
                        KeypadButton(text: "0") {
                            appendDigit("0")
                        }
                        
                        Button(action: removeDigit) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 70, height: 70)
                                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                
                                Image(systemName: "delete.backward.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                
                Button(action: handleNextStep) {
                    Text("التالي")
                        .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 55)
                    .supernovaGlassCapsule(
                        tint: enteredPin.count == 4 ? .tealPrimary : Color(hex: "#5A648D"),
                        opacity: enteredPin.count == 4 ? 0.68 : 0.72
                    )
                }
                .disabled(enteredPin.count < 4)
                .padding(.top, 10)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToChildProfile) {
            if hasCompletedChildSetup {
                TasksListView()
            } else {
                ChildInfoSetupView()
            }
        }
        .onAppear {
            if savedPin.isEmpty { step = .create } else { step = .enter }
        }
    }
    
    private var headerTitle: String {
        switch step {
        case .create: return "أنشئ رمز PIN المكون من ٤ أرقام"
        case .confirm: return "تأكيد رمز PIN"
        case .enter: return "أدخل رمز PIN المكون من ٤ أرقام"
        }
    }
    
    private var headerSubtitle: String {
        switch step {
        case .create: return "يرجى اختيار رمز جديد للمتابعة"
        case .confirm: return "أعد إدخال الرمز للتأكيد"
        case .enter: return "يرجى التحقق من هويتك للمتابعة"
        }
    }
    
    private func handleBackButton() {
        if step == .confirm {
            step = .create; enteredPin = ""; tempFirstPin = ""; errorMessage = ""
        } else { dismiss() }
    }
    
    private func appendDigit(_ digit: String) {
        if enteredPin.count < 4 { enteredPin.append(digit); errorMessage = "" }
    }
    
    private func removeDigit() {
        if !enteredPin.isEmpty { enteredPin.removeLast(); errorMessage = "" }
    }
    
    private func handleNextStep() {
        guard enteredPin.count == 4 else { return }
        switch step {
        case .create:
            tempFirstPin = enteredPin; enteredPin = ""; step = .confirm
        case .confirm:
            if enteredPin == tempFirstPin { savedPin = enteredPin; navigateToChildProfile = true }
            else { errorMessage = "الرمز غير مطابق، حاول مرة أخرى"; enteredPin = "" }
        case .enter:
            if enteredPin == savedPin { navigateToChildProfile = true }
            else { errorMessage = "الرمز خاطئ، يرجى المحاولة مجدداً"; enteredPin = "" }
        }
    }
}

// MARK: - 7. الشاشة الرابعة: إعداد معلومات الطفل (ChildInfoSetupView)
struct ChildInfoSetupView: View {
    @State private var childName: String = ""
    @State private var selectedAge: Int? = nil
    @State private var navigateToParentDashboard = false
    @AppStorage("childProfileName") private var savedChildName = ""
    @AppStorage("childProfileAge") private var savedChildAge = 0
    @AppStorage("hasCompletedChildSetup") private var hasCompletedChildSetup = false
    
    @Environment(\.dismiss) var dismiss
    let ageOptions = Array(6...12)
    
    var body: some View {
        ZStack {
            SpaceBackgroundView()
            
            VStack {
                HStack {
                    BackCapsuleButton { dismiss() }
                    Spacer()
                }
                .padding(.top, AppHeaderLayout.top)
                .padding(.leading, AppHeaderLayout.horizontal)
                Spacer()
            }
            .zIndex(10)
            
            VStack(spacing: 35) {
                Spacer()
                
                VStack(spacing: 10) {
                    Text("إعداد معلومات الطفل")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color("tiffany")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color("tiffany").opacity(0.5), radius: 15)
                    
                    Text("أدخل بيانات طفلك لتخصيص التجربة المناسبة له")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                VStack(alignment: .trailing, spacing: 28) {
                    VStack(alignment: .trailing, spacing: 10) {
                        HStack(spacing: 8) {
                            Spacer()
                            Text("اسم الطفل")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color("tiffany"))
                        }
                        
                        TextField("أدخل اسم الطفل...", text: $childName)
                            .font(.system(size: 18, weight: .medium))
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), Color("tiffany").opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                    
                    VStack(alignment: .trailing, spacing: 10) {
                        HStack(spacing: 8) {
                            Spacer()
                            Text("العمر (بالسنوات)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundColor(Color("tiffany"))
                        }
                        
                        Menu {
                            ForEach(ageOptions, id: \.self) { age in
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedAge = age
                                    }
                                }) {
                                    HStack {
                                        if selectedAge == age {
                                            Image(systemName: "checkmark")
                                        }
                                        Text("\(age) سنوات")
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color("tiffany"))
                                
                                Spacer()
                                
                                if let age = selectedAge {
                                    Text("\(age) سنوات")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Text("اختر العمر من القائمة...")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                
                                Image(systemName: "calendar")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color("tiffany").opacity(0.8))
                                    .padding(.leading, 6)
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.12),
                                                Color.purple.opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        LinearGradient(
                                            colors: selectedAge != nil ?
                                                [Color("tiffany"), Color.purple.opacity(0.6)] :
                                                [Color.white.opacity(0.25), Color.white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: selectedAge != nil ? 1.8 : 1
                                    )
                            )
                            .shadow(color: selectedAge != nil ? Color("tiffany").opacity(0.3) : Color.clear, radius: 10)
                        }
                    }
                }
                .padding(32)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.22, green: 0.14, blue: 0.38).opacity(0.85),
                                        Color(red: 0.12, green: 0.08, blue: 0.25).opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Circle()
                            .fill(Color("tiffany").opacity(0.15))
                            .frame(width: 180, height: 180)
                            .blur(radius: 40)
                            .offset(x: -120, y: -80)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color("tiffany").opacity(0.6),
                                    Color.purple.opacity(0.4),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 30, x: 0, y: 15)
                .shadow(color: Color("tiffany").opacity(0.15), radius: 20, x: 0, y: 0)
                .frame(maxWidth: 500)
                .padding(.horizontal, 24)
                
                Button(action: {
                    if let age = selectedAge {
                        savedChildName = childName.trimmingCharacters(in: .whitespacesAndNewlines)
                        savedChildAge = age
                        hasCompletedChildSetup = true
                        navigateToParentDashboard = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("متابعة")
                            .font(.system(size: 22, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(width: 260, height: 58)
                    .supernovaGlassCapsule(
                        tint: isFormValid ? .tealPrimary : Color(hex: "#5A648D"),
                        opacity: isFormValid ? 0.68 : 0.72
                    )
                }
                .disabled(!isFormValid)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToParentDashboard) {
            TasksListView()
        }
        .onAppear {
            // Keep the saved information if this screen is ever opened again
            // deliberately from a future profile/settings screen.
            if childName.isEmpty { childName = savedChildName }
            if selectedAge == nil, savedChildAge > 0 { selectedAge = savedChildAge }
        }
    }
    
    private var isFormValid: Bool {
        return !childName.trimmingCharacters(in: .whitespaces).isEmpty && selectedAge != nil
    }
}

// MARK: - 8. مكون أزرار لوحة الأرقام
struct KeypadButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle().fill(Color.white.opacity(0.10))
                    )
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.32), lineWidth: 1)
                    )
                
                Text(text)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - المعاينة
#Preview {
    WelcomeView()
}
