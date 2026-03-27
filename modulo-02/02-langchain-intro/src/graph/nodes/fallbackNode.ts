import { AIMessage, SystemMessage } from 'langchain'
import { type GraphState } from '../graph.ts'

export function fallbackNode(state: GraphState): GraphState {
    const message = "Unknown command. Try 'make this uppercase' or 'make this lowercase'."
    const responseText = new AIMessage(message).content.toString()

    return {
        ...state,
        output: message,
        messages: [
            ...state.messages,
            new SystemMessage('hey there!')
        ]
    }
}

