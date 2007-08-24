 package {
	
	import flash.display.BitmapData;
	import org.papervision3d.events.InteractiveScene3DEvent;
	import org.papervision3d.scenes.MovieScene3D;
	import org.papervision3d.cameras.Camera3D;
	import org.papervision3d.objects.*;
	import org.papervision3d.materials.*;
	import org.papervision3d.utils.*;
	import org.papervision3d.objects.Sphere;

	import flash.events.Event;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.BlendMode;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.geom.Matrix;
	import org.papervision3d.scenes.InteractiveScene3D;
	
//do3d.addEventListener(InteractiveScene3DEvent.OBJECT_CLICK, handleClick);
//private function handleClick(e:InteractiveScene3DEvent):void


	[SWF(backgroundColor="0xFFFFFF", frameRate="31")]
	public class Main extends Sprite {		
		protected var container 				:Sprite;
		protected var scene     				:InteractiveScene3D;
		protected var camera   					:Camera3D;
		protected var ism						:InteractiveSceneManager;
		protected var plane	 	 				:Plane;
		
		public function Main() {
			init();
		}
		public function init():void {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			init3D();
			createPlane();
			addEventListener(Event.ENTER_FRAME, loop);
		}
		protected function init3D():void {
			container = new InteractiveSprite();
			addChild(container);
			container.name = "mainCont";
			container.x = stage.stageWidth*.5;
			container.y = stage.stageHeight*.5;
	
			scene = new InteractiveScene3D(container);
			ism = scene.interactiveSceneManager;
			
			camera = new Camera3D();
			camera.zoom = 3;
			camera.focus = 500;
		}
		protected function createPlane():void {
			var material:InteractiveColorMaterial = new InteractiveColorMaterial(0x00ff00);
			
			plane = new Plane( material, 500, 500, 8, 8 );
			plane.addEventListener(InteractiveScene3DEvent.OBJECT_CLICK, handleMainClick);
			scene.addChild(plane);
		}
		protected function loop(event:Event):void {
			camera.x = -(container.mouseX * 3)/2;
			camera.y = (container.mouseY * 3);
			scene.renderCamera(camera);
		}
		protected function handleMainClick(e:InteractiveScene3DEvent):void {
			trace("mouse click from: ", e.currentTarget, e.displayObject3D, e.sprite);
		}
	}
}



