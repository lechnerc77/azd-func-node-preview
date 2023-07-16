const { app } = require('@azure/functions');

app.http('sendEmail', {
    methods: ['POST'],
    authLevel: 'function',
    handler: async (request, context) => {
        context.log(`HTTP triggered function processed request for url "${request.url}"`);

        const requestBody = await request.json();
        context.log(requestBody);

        return { body: `Hello, world! Welcome to Azure Functions with the new programming model ${requestBody.name}` };
    }
});