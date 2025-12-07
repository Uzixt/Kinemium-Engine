local color = require(script.Parent.color)
local lucide = require(script.Parent.Parent.libs.Lucide)
local pages = require(script.Parent.pages)

export type ColorTypes = color.ColorNames

export type BaseGui = {
	Name: string,
	Parent: Instance?,
	ClassName: string,
	Archivable: boolean,
	AbsolutePosition: Vector2,
	AbsoluteSize: Vector2,
	AutoLocalize: boolean,
	RootLocalizationTable: LocalizationTable?,
	SelectionImageObject: GuiObject?,
	Active: boolean,
	AnchorPoint: Vector2,
	AutomaticSize: Enum.AutomaticSize,
	BackgroundColor3: Color3,
	BackgroundTransparency: number,
	BorderColor3: Color3,
	BorderMode: Enum.BorderMode,
	BorderSizePixel: number,
	ClipsDescendants: boolean,
	Draggable: boolean,
	LayoutOrder: number,
	NextSelectionDown: GuiObject?,
	NextSelectionLeft: GuiObject?,
	NextSelectionRight: GuiObject?,
	NextSelectionUp: GuiObject?,
	Position: UDim2,
	Rotation: number,
	Selectable: boolean,
	SelectionOrder: number,
	Size: UDim2,
	SizeConstraint: Enum.SizeConstraint,
	Transparency: number?,
	Visible: boolean,
	ZIndex: number,

	Changed: (Object: GuiObject, property: string, newValue: any) -> (),
	Destroying: (Object: GuiObject) -> (),
	GetPropertyChangedSignal: (Object: GuiObject, property: string) -> (),

	MouseEnter: (Object: GuiObject, x: number, y: number) -> (),
	MouseLeave: (Object: GuiObject, x: number, y: number) -> (),
	MouseMoved: (Object: GuiObject, x: number, y: number) -> (),
	MouseButton1Click: (Object: GuiObject, x: number, y: number) -> (),
	MouseButton1Down: (Object: GuiObject, x: number, y: number) -> (),
	MouseButton1Up: (Object: GuiObject, x: number, y: number) -> (),
	MouseButton2Click: (Object: GuiObject, x: number, y: number) -> (),
	MouseButton2Down: (Object: GuiObject, x: number, y: number) -> (),
	MouseButton2Up: (Object: GuiObject, x: number, y: number) -> (),
	MouseWheelForward: (Object: GuiObject, x: number, y: number) -> (),
	MouseWheelBackward: (Object: GuiObject, x: number, y: number) -> (),

	InputBegan: (Object: GuiObject, input: InputObject) -> (),
	InputChanged: (Object: GuiObject, input: InputObject) -> (),
	InputEnded: (Object: GuiObject, input: InputObject) -> (),

	TouchLongPress: (Object: GuiObject, touchPositions: { Vector2 }, state: Enum.UserInputState) -> (),
	TouchPan: (
		Object: GuiObject,
		touchPositions: { Vector2 },
		totalTranslation: Vector2,
		velocity: Vector2,
		state: Enum.UserInputState
	) -> (),
	TouchPinch: (
		Object: GuiObject,
		touchPositions: { Vector2 },
		scale: number,
		velocity: number,
		state: Enum.UserInputState
	) -> (),
	TouchRotate: (
		Object: GuiObject,
		touchPositions: { Vector2 },
		rotation: number,
		velocity: number,
		state: Enum.UserInputState
	) -> (),
	TouchSwipe: (Object: GuiObject, swipeDirection: Enum.SwipeDirection, numberOfTouches: number) -> (),
	TouchTap: (Object: GuiObject, touchPositions: { Vector2 }) -> (),

	[any]: any,
}

export type LuaCSSObject = {
	class: string?,
	width: ({ number }) -> ()?,
	height: ({ number }) -> ()?,
	position: ({ number }) -> ()?,
	anchor: ({ number }) -> ()?,
	hovered: (callback: (GuiObject) -> ()) -> ()?,
	left: (callback: (GuiObject) -> ()) -> ()?,
	size: ({ number }) -> ()?,
	groundcolor: (color: Color3 | ColorTypes | string) -> ()?,
	groundtransparency: (transparency: number) -> ()?,
	borderColor: (color: Color3 | ColorTypes | string) -> ()?,
	rotation: (rotation: number) -> ()?,
	visible: (visible: boolean) -> ()?,
	paddingvertical: ({ number }) -> ()?,
	gridmaxcells: ({ number }) -> ()?,
	gridpadding: ({ number }) -> ()?,
	allowClipping: (bool: boolean) -> ()?,
	paddingtop: ({ number }) -> ()?,
	shadow: {
		Image: string?,
		ImageTransparency: number?,
		Scale: number?,
		Color: (Color3 | ColorTypes | string)?,
		Parent: Instance?,
		ZIndex: number?,
	}?,
	paddingright: ({ number }) -> ()?,
	paddingbottom: ({ number }) -> ()?,
	paddingleft: ({ number }) -> ()?,
	alignment: (
		"top"
		| "center"
		| "bottom"
		| "left"
		| "right"
		| "top left"
		| "top center"
		| "top right"
		| "center left"
		| "center center"
		| "center right"
		| "bottom left"
		| "bottom center"
		| "bottom right"
	)?,
	list: ("horizontal" | "vertical" | { any })?,
	parent: (parent: GuiObject) -> ()?,
	spawn: { [string]: Object }?,
	text: string?,
	style: string?,
	multistyle: { string }?,
	heartbeat: (callback: (GuiObject, RBXScriptConnection) -> ()) -> ()?,
	stepped: (callback: (GuiObject, RBXScriptConnection) -> ()) -> ()?,
	target: ({ any }) -> ()?,
	autosize: Enum.AutomaticSize?,
	txtsize: number?,
	txtcolor: (Color3 | ColorTypes | string)?,
	font: Enum.Font?,
	txtvisible: number?,
	radius: ({ number }) -> ()?,
	clicked: (callback: (GuiButton) -> ()) -> ()?,
	padding: ({ number }) -> ()?,
	animlist: ({ any }) -> ()?,
	grid: ({ any }) -> ()?,
	drag: (data: any?) -> ()?,
	camera: (callback: (GuiObject) -> Camera?) -> ()?,
	cframe: CFrame?,
	canvasEnabled: boolean?,
	autofill: boolean?,
	maid: (event: any) -> ()?,
	clean: (tbl: any) -> ()?,
	cleanevents: boolean?,
	rounded: ({ number }) -> ()?,
	hovercolor: {
		Value: Color3 | ColorTypes | string,
		Animated: boolean?,
		Damping: number?,
		Frequency: number?,
	}?,
	hovertransparency: {
		Value: number,
		Animated: boolean?,
		Damping: number?,
		Frequency: number?,
	}?,
	leavetransparency: {
		Value: number,
		Animated: boolean?,
		Damping: number?,
		Frequency: number?,
	}?,
	leavecolor: {
		Value: Color3 | ColorTypes | string,
		Animated: boolean?,
		Damping: number?,
		Frequency: number?,
	}?,
	animate: {
		Value: any,
		Property: string?,
		Damping: number?,
		Frequency: number?,
	}?,
	image: string?,
	inframe: boolean?,
	autoscalebased: {
		Padding: { number },
		Enum: Enum.AutomaticSize?,
	}?,
	run: (func: (GuiObject) -> any?) -> ()?,
	runinsert: (func: (GuiObject) -> any?) -> ()?,
	states: { [string]: (GuiObject) -> () }?,
	_applytoall: Object?,
	editbody: Object?,
	pta: Object?,
	state: string?,
	gradient: {
		Color: ColorSequence?,
		Transparency: NumberSequence?,
		Rotation: number?,
	}?,
	border: boolean?,
	cornerRadius: ({ number }) -> ()?,
	editChildren: { [string]: Object }?,
	paddingsides: ({ number }) -> ()?,
	id: string?,
	name: string?,
	layoutOrder: number?,
	wrap: (data: { Instance }) -> ()?,
	squircle: boolean?,
	getalignment: (pos: string) -> (UDim2, Vector2)?,
	zindex: number?,
	center: boolean?,
	offset: UDim2?,
	borderwidth: number?,
	opacity: number?,
	debugoutline: boolean?,
	flexrow: number?,
	flexcolumn: number?,
	changedsignal: { property: string, callback: () -> (Instance, any) },
	fit: {
		Ratio: number?,
		DominantAxis: Enum.DominantAxis?,
	}?,
	fitToDevice: {
		Scale: number?,
		AspectRatio: number?,
		DominantAxis: Enum.DominantAxis?,
		UseAspect: boolean?,
	}?,
	textStroke: {
		Thickness: number?,
		Color: (Color3 | ColorTypes | string)?,
	}?,
	textAlignment: ("left" | "center" | "right")?,
	textVerticalAlignment: ("top" | "center" | "bottom")?,
	fadeIn: {
		Duration: number?,
		Delay: number?,
	}?,
	fadeOut: {
		Duration: number?,
		Delay: number?,
	}?,
	slideIn: {
		Direction: ("left" | "right" | "top" | "bottom")?,
		Duration: number?,
		Delay: number?,
	}?,
	aspectRatio: number?,
	maxWidth: number?,
	minWidth: number?,
	disabled: boolean?,
	hover: {
		Enter: ((GuiObject) -> ())?,
		Leave: ((GuiObject) -> ())?,
	}?,
	clone: (parent: Instance?) -> ()?,
	hide: boolean?,
	show: boolean?,
	toggle: boolean?,
	flex: number?,
	placeholder: string?,
	selectable: boolean?,
	lowerzindex: boolean?,
	raisezindex: boolean?,
	textwrapped: boolean?,
	richtext: boolean?,
	scrollable: {
		Direction: ("vertical" | "horizontal")?,
		CanvasHeight: number?,
		CanvasWidth: number?,
		Thickness: number?,
	}?,
	scale: number?,
	display: ("none" | "block" | "flex")?,
	overflow: ("hidden" | "scroll" | "auto" | "visible")?,
	transform: {
		rotate: number?,
		scale: number?,
	}?,
	cursor: ("pointer" | "default" | "not-allowed")?,
	pointerEvents: ("none" | "auto")?,
	lineHeight: number?,
	textTransform: ("uppercase" | "lowercase" | "capitalize")?,
	textOverflow: ("ellipsis" | "clip")?,
	whiteSpace: ("nowrap" | "normal" | "wrap")?,
	filter: {
		brightness: number?,
		transparency: number?,
	}?,
	gap: number?,
	justifyContent: ("flex-start" | "start" | "center" | "flex-end" | "end" | "space-between")?,
	alignItems: ("flex-start" | "center" | "flex-end")?,
	objectFit: ("cover" | "contain" | "fill" | "none")?,
	margin: ({ number }) -> ()?,
	background: (Color3 | ColorTypes | string | {
		color: (Color3 | ColorTypes | string)?,
		transparency: number?,
		image: string?,
	})?,
	borderStyle: {
		width: number?,
		style: string?,
		color: (Color3 | ColorTypes | string)?,
	}?,
}
export type BuilderMethods = {
	class: (self: BuilderMethods, className: string) -> BuilderMethods,
	name: (self: BuilderMethods, name: string) -> BuilderMethods,
	parent: (self: BuilderMethods, parent: Instance?) -> BuilderMethods,
	set: (self: BuilderMethods, property: string, value: any) -> BuilderMethods,
	merge: (self: BuilderMethods, properties: Object) -> BuilderMethods,
	build: (self: BuilderMethods) -> (Instance, any, any),
	buildProperties: (self: BuilderMethods) -> Object,
	applyTo: (self: BuilderMethods, object: Instance) -> Instance,
	[any]: (self: BuilderMethods, ...any) -> BuilderMethods,
}

export type Value<T> = {
	get: () -> T,
	set: (newValue: T) -> (),
	subscribe: (callback: (T) -> ()) -> () -> (),
	filter: ((T) -> boolean) -> Value<T>,
	computed: (() -> T) -> Value<T>,
	bind: ((T) -> ()) -> (T) -> (),
}

export type EnvValueObject = {
	Set: (new: any) -> (),
	Data: any,
	Changed: RBXScriptConnection,
	Get: () -> any,
	Remove: () -> (),
	Reload: () -> (),
}

export type IdObject = {
	Value: string,
	Edit: (Object) -> Instance,
	Change: (string) -> (),
	Destroy: () -> (),
}

export type ThemeObject = {
	Set: (new: { [string]: any }) -> (),
	SetProperty: (new: any) -> (),
	Data: any,
	Changed: RBXScriptConnection,
	Get: () -> any,
	Remove: () -> (),
	Reload: () -> (),
}

export type ComponentReplicateParams = {
	newProps: Object,
	class: string,
}

export type PropertyReplicateParams = {
	UseSpring: boolean,
}

export type ComponentObject = {
	makeGlobal: () -> (),
	Destroy: () -> (),
	Reload: () -> any,
	Inspect: () -> any,
	Update: (newData: any) -> (),
	UpdatedEvent: RBXScriptSignal,
	Value: any,
}

export type ChainableBuilder = BuilderMethods & LuaCSSObject & BaseGui
export type Object = LuaCSSObject & BaseGui

export type LuaCSSExtension = {
	name: string?,
	env: { [string]: any }?, -- theme & shared values
	handlers: { [string]: (object: any, value: any) -> () }?, -- custom property handling
	components: { [string]: Object }?, -- spawn rules for subobjects
	init: ((css: any, LuaCSSExtension) -> ())?, -- optional: run on insert
}
export type LuaCSS = {
	Enums: {
		anchors: {
			TopLeft: { number },
			TopCenter: { number },
			TopRight: { number },
			MiddleLeft: { number },
			MiddleCenter: { number },
			MiddleRight: { number },
			BottomLeft: { number },
			BottomCenter: { number },
			BottomRight: { number },
		},
	},

	Events: {
		Cache: { any },
		getpos: (anchorPoint: { number }) -> UDim2,
		ObjectCreated: RBXScriptSignal,
	},

	methods: any,
	Types: any,

	withLogs: <T>(() -> T) -> T,
	enableLogs: () -> (),
	ProcessPropertyValue: (property: string, value: any, object: Instance, properties: any) -> (),

	state: (object: Instance, state: string) -> (),
	cleanevent: (object: Instance, customfunctionName: string) -> (),
	builder: () -> ChainableBuilder,

	value: <T>(initial: T) -> Value<T>,
	janitor: () -> any,
	scope: () -> any,
	cleaner: any,

	reloadAll: () -> (),
	springSettings: (damping: number, frequency: number) -> (),
	getDamping: () -> number,
	getFrequency: () -> number,
	spring: (obj: Instance, properties: any) -> (),

	translate: (any) -> { any },
	pages: pages.Module,
	style: (name: string, properties: any) -> any,
	getEnvValue: (name: string) -> any,
	EnvValueExists: (name: string) -> boolean,
	addEnvValue: (name: string, value: any) -> any,
	getGlobalComponents: () -> any,
	invertColor: (c: Color3 | string) -> Color3?,
	addEnvKey: (propertyName: string, prefix: string) -> any,

	component: (name: string, data: {} | Instance | ModuleScript) -> ComponentObject,

	fromInstance: (object: Instance) -> any,
	edit: (object: Instance, properties: any) -> GuiObject,
	compileObject: (properties: any, logs: boolean?) -> (Instance, any, any),
	theme: (color: Color3) -> any,
	compile: (data: { [string]: any }) -> { Instance },
}

return nil
