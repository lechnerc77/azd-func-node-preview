const { app } = require('@azure/functions');
const { json } = require('stream/consumers')

app.http('sendEmail', {
    methods: ['POST'],
    handler: async (request, context) => {
        context.log(`HTTP triggered function processed request for url "${request.url}"`);

        const data = await json(request.body);
        context.log(data);

        return { body: `Hello, world! Welcome to Azure Functions with the new programming model ${data.name}` };
    }
});