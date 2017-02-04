using concurrent::Actor
using concurrent::ActorPool
using concurrent::AtomicInt
using concurrent::Future

** Provides 'synchronized' access to a (non- 'const') mutable state object.
** 
** 'SynchronizedState' creates the state object in its own thread and provides access to it via the 
** 'withState()' and 'getState()' methods. Note that by their nature, these methods are immutable 
** boundaries. Meaning that while data in the State object can be mutable, data passed in and out 
** of these these boundaries can not be. 
** 
** 'SynchronizedState' is designed to be *scope safe*, that is you cannot accidently call methods 
** on your State object outside of the 'withState()' and 'getState()' methods. 
** 
** Example usage:
** 
** pre>
** syntax: fantom
**  
** sync := SynchronizedState(ActorPool(), Mutable#)
** msg  := "That's cool, dude!"
** 
** val  := sync.getState |Mutable state -> Int| {
**     state.buf.writeChars(msg)
**     return state.buf.size
** }
** 
** class Mutable {
**     Buf buf := Buf()
** }
** <pre
const class SynchronizedState {
	private const |->Obj?| 		stateFactory
	private const LocalRef 		stateRef
	
	** The 'lock' object should you need to 'synchronize' on the state.
	const Synchronized	lock

	** The given state type must have a public no-args ctor as per [Type.make]`sys::Type.make`.
	new makeWithType(ActorPool actorPool, Type stateType) {
		this.lock			= Synchronized(actorPool) 
		this.stateRef		= LocalRef(stateType.name)
		this.stateFactory	= |->Obj?| { stateType.make }		
	}

	** The given (immutable) factory func is used to create the state object inside it's thread.
	new makeWithFactory(ActorPool actorPool, |->Obj?| stateFactory) {
		this.lock			= Synchronized(actorPool) 
		this.stateRef		= LocalRef(SynchronizedState#.name)
		this.stateFactory	= stateFactory
	}

	** Calls the given func asynchronously, passing in the State object.
	** 
	** The given func should be immutable. 
	Future withState(|Obj state -> Obj?| func) {
		iFunc := func.toImmutable
		return lock.async |->Obj?| { callFunc(iFunc) }
	}

	** Calls the given func synchronously, passing in the State object and returning the func's 
	** response.
	**  
	** The given func should be immutable. 
	Obj? getState(|Obj state -> Obj?| func) {
		iFunc := func.toImmutable
		return lock.synchronized |->Obj?| { callFunc(iFunc) }
	}
	
	private Obj? callFunc(|Obj?->Obj?| func) {
		if (stateRef.val == null) 
			stateRef.val = stateFactory.call		
		return func.call(stateRef.val)		
	}
}

